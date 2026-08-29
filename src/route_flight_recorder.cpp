#include "route_flight_recorder.h"

#include <Windows.h>

#include <algorithm>
#include <cstdio>
#include <thread>

namespace w3vr::route_flight {
namespace {

Recorder g_recorder{};

bool build_dump_path(std::wstring& path) {
    HMODULE module{};
    const auto address = reinterpret_cast<LPCWSTR>(
        reinterpret_cast<uintptr_t>(&dump_last_seconds));
    if (!GetModuleHandleExW(
            GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
                GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
            address, &module)) {
        return false;
    }

    wchar_t module_path[MAX_PATH]{};
    if (GetModuleFileNameW(module, module_path, MAX_PATH) == 0) {
        return false;
    }
    wchar_t* slash = wcsrchr(module_path, L'\\');
    if (slash == nullptr) {
        return false;
    }
    slash[1] = L'\0';

    SYSTEMTIME local{};
    GetLocalTime(&local);
    wchar_t filename[160]{};
    _snwprintf_s(
        filename, _TRUNCATE,
        L"witcher3vr-route-flight_%04u%02u%02u_%02u%02u%02u_%03u_%lu.log",
        local.wYear, local.wMonth, local.wDay,
        local.wHour, local.wMinute, local.wSecond, local.wMilliseconds,
        static_cast<unsigned long>(GetCurrentProcessId()));
    path = module_path;
    path += filename;
    return true;
}

}  // namespace

void Recorder::set_enabled(bool enabled) noexcept {
    enabled_.store(enabled, std::memory_order_release);
}

bool Recorder::enabled() const noexcept {
    return enabled_.load(std::memory_order_relaxed);
}

void Recorder::record(Event event) noexcept {
    if (!enabled_.load(std::memory_order_relaxed)) {
        return;
    }
    if (paused_.load(std::memory_order_seq_cst)) {
        skipped_while_paused_.fetch_add(1, std::memory_order_relaxed);
        return;
    }

    active_writers_.fetch_add(1, std::memory_order_seq_cst);
    if (paused_.load(std::memory_order_seq_cst)) {
        active_writers_.fetch_sub(1, std::memory_order_seq_cst);
        skipped_while_paused_.fetch_add(1, std::memory_order_relaxed);
        return;
    }

    const uint64_t sequence = next_sequence_.fetch_add(
        1, std::memory_order_relaxed);
    event.sequence = sequence + 1;
    events_[sequence % kCapacity] = event;
    active_writers_.fetch_sub(1, std::memory_order_seq_cst);
}

Snapshot Recorder::capture_since(int64_t minimum_qpc) {
    paused_.store(true, std::memory_order_seq_cst);
    while (active_writers_.load(std::memory_order_seq_cst) != 0) {
        std::this_thread::yield();
    }

    Snapshot snapshot{};
    snapshot.total_claimed = next_sequence_.load(std::memory_order_relaxed);
    const uint64_t first_sequence = snapshot.total_claimed > kCapacity
        ? snapshot.total_claimed - kCapacity
        : 0;
    snapshot.overwritten = first_sequence;
    snapshot.events.reserve(static_cast<size_t>(
        snapshot.total_claimed - first_sequence));
    for (uint64_t sequence = first_sequence;
         sequence < snapshot.total_claimed; ++sequence) {
        const auto& event = events_[sequence % kCapacity];
        if (event.sequence != sequence + 1 || event.qpc < minimum_qpc) {
            continue;
        }
        snapshot.events.push_back(event);
    }

    paused_.store(false, std::memory_order_seq_cst);
    snapshot.skipped_while_paused = skipped_while_paused_.exchange(
        0, std::memory_order_relaxed);
    return snapshot;
}

void set_enabled(bool enabled) noexcept {
    g_recorder.set_enabled(enabled);
}

bool enabled() noexcept {
    return g_recorder.enabled();
}

void record(Event event) noexcept {
    g_recorder.record(event);
}

bool dump_last_seconds(
    const char* build_identity,
    uint32_t window_seconds,
    std::wstring* written_path) {
    if (!enabled()) {
        return false;
    }

    LARGE_INTEGER now{};
    LARGE_INTEGER frequency{};
    if (!QueryPerformanceCounter(&now) ||
        !QueryPerformanceFrequency(&frequency) || frequency.QuadPart <= 0) {
        return false;
    }
    const int64_t minimum_qpc = now.QuadPart -
        frequency.QuadPart * static_cast<int64_t>(window_seconds);
    auto snapshot = g_recorder.capture_since(minimum_qpc);

    std::wstring path;
    if (!build_dump_path(path)) {
        return false;
    }
    FILE* file{};
    if (_wfopen_s(&file, path.c_str(), L"w") != 0 || file == nullptr) {
        return false;
    }

    fprintf(file,
        "# Witcher3VR route flight recorder build=%s window=%us hotkey=F3\n",
        build_identity != nullptr ? build_identity : "unknown",
        window_seconds);
    fprintf(file,
        "# events=%zu total_claimed=%llu overwritten=%llu skipped_during_snapshot=%llu qpc_frequency=%lld\n",
        snapshot.events.size(),
        static_cast<unsigned long long>(snapshot.total_claimed),
        static_cast<unsigned long long>(snapshot.overwritten),
        static_cast<unsigned long long>(snapshot.skipped_while_paused),
        static_cast<long long>(frequency.QuadPart));
    fprintf(file,
        "# No GPU readbacks, descriptor scans, per-draw timing, text formatting, or file I/O occur before F3.\n");
    fprintf(file,
        "# Common flags: success=0x1 exact=0x2 active=0x4 fallback=0x8 stale=0x10 reset=0x20. Event-specific details follow the source marker.\n");
    fprintf(file,
        "# smoke_select: stage=1 eye_variant_draw, 2 zero_center_draw, 3 original_draw; d=reason,final_variant(0/1/2/UINT_MAX),selected_distance_float_bits,separation_margin_float_bits.\n");
    fprintf(file,
        "# smoke_select reason: 1=asym_inactive 2=dlss_tag 3=eye_cache 4=exact_camera 5=paired_camera 10=no_state 11=no_cbv 12=small_cbv 13=no_mapped_camera 14=bad_matrix 15=bad_camera 16=camera_rejected 17=no_eye_pso 18=no_zero_pso 19=no_root_tables 20=route_inactive 21=no_hooks.\n");

    std::array<uint64_t, static_cast<size_t>(EventCode::Count)> counts{};
    for (const auto& event : snapshot.events) {
        const size_t index = static_cast<size_t>(event.code);
        if (index < counts.size()) {
            ++counts[index];
        }
    }
    fprintf(file, "# summary\n");
    for (size_t index = 0; index < counts.size(); ++index) {
        if (counts[index] == 0) {
            continue;
        }
        fprintf(file, "#   %-20s %llu\n",
            event_code_name(static_cast<EventCode>(index)),
            static_cast<unsigned long long>(counts[index]));
    }
    fprintf(file,
        "# columns: ms_to_dump sequence present event stage tid eye pair previous generation flags detail0 detail1 detail2 detail3\n");
    for (const auto& event : snapshot.events) {
        const double milliseconds = static_cast<double>(
            event.qpc - now.QuadPart) * 1000.0 /
            static_cast<double>(frequency.QuadPart);
        fprintf(file,
            "%10.3f %10llu p=%llu %-20s stage=%u tid=%u eye=%d pair=%llu prev=%llu gen=%u flags=0x%08X d=%u,%u,%u,%u\n",
            milliseconds,
            static_cast<unsigned long long>(event.sequence),
            static_cast<unsigned long long>(event.present),
            event_code_name(event.code), event.stage, event.thread_id,
            event.eye,
            static_cast<unsigned long long>(event.pair_id),
            static_cast<unsigned long long>(event.previous_pair_id),
            event.generation, event.flags,
            event.detail0, event.detail1, event.detail2, event.detail3);
    }
    fclose(file);
    if (written_path != nullptr) {
        *written_path = path;
    }
    OutputDebugStringW(L"Witcher3VR route flight recorder dumped by F3\n");
    return true;
}

const char* event_code_name(EventCode code) noexcept {
    switch (code) {
    case EventCode::Present: return "present";
    case EventCode::PresentEnd: return "present_end";
    case EventCode::EngineTaskBegin: return "engine_task_begin";
    case EventCode::EngineTaskEnd: return "engine_task_end";
    case EventCode::DlssEmit: return "dlss_emit";
    case EventCode::DlssCommand: return "dlss_command";
    case EventCode::DlssConstants: return "dlss_constants";
    case EventCode::DlssTag: return "dlss_tag";
    case EventCode::DlssEvaluate: return "dlss_evaluate";
    case EventCode::TaauResolve: return "taau_resolve";
    case EventCode::TaauSubmission: return "taau_submission";
    case EventCode::AfwCapture: return "afw_capture";
    case EventCode::AfwFinalize: return "afw_finalize";
    case EventCode::AfwEvaluate: return "afw_evaluate";
    case EventCode::AfwPublish: return "afw_publish";
    case EventCode::HudState: return "hud_state";
    case EventCode::RouteReset: return "route_reset";
    case EventCode::SmokeSelect: return "smoke_select";
    case EventCode::Count: break;
    }
    return "unknown";
}

}  // namespace w3vr::route_flight
