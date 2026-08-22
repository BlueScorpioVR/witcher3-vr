#include "smoke_visibility_recorder.h"

#include "smoke_visibility_policy.h"

#include <Windows.h>

#include <algorithm>
#include <array>
#include <atomic>
#include <cstdio>
#include <mutex>
#include <unordered_map>
#include <vector>

namespace w3vr::smoke_visibility {
namespace {

constexpr uint32_t kCapacity = 65536;

enum class SampleState : uint8_t {
    Empty = 0,
    Recording,
    PendingExecute,
    Submitted,
    Abandoned,
};

struct Sample {
    DrawMetadata metadata{};
    uint64_t sequence{};
    uint64_t submission_serial{};
    int64_t qpc{};
    uint32_t thread_id{};
    SampleState state{SampleState::Empty};
    bool query_started{};
};

struct DumpRow {
    Sample sample{};
    D3D12_QUERY_DATA_PIPELINE_STATISTICS statistics{};
    bool gpu_ready{};
};

std::array<Sample, kCapacity> g_samples{};
std::atomic<uint32_t> g_next_sample{};
std::atomic<uint64_t> g_dropped_capacity{};
std::atomic<uint64_t> g_dropped_paused{};
std::atomic<uint64_t> g_present{};
std::atomic<int64_t> g_present_qpc{};
std::atomic<bool> g_paused{};
std::mutex g_mutex{};
std::unordered_map<ID3D12CommandList*, std::vector<uint32_t>>
    g_pending_by_command_list{};
std::vector<ID3D12CommandQueue*> g_seen_queues{};
uint64_t g_submission_serial{};
ID3D12Device* g_device{};
ID3D12QueryHeap* g_query_heap{};
ID3D12Resource* g_readback{};
D3D12_QUERY_DATA_PIPELINE_STATISTICS* g_mapped_statistics{};
bool g_initialized{};

const char* projection_name(uint32_t projection) noexcept {
    switch (projection) {
    case 1: return "shared_sym";
    case 2: return "native_asym";
    default: return "invalid";
    }
}

const char* route_name(uint32_t flags) noexcept {
    if ((flags & DrawRouteAer) != 0) return "aer";
    if ((flags & DrawRouteStereo) != 0) return "stereo";
    return "unknown";
}

const char* backend_name(uint32_t flags) noexcept {
    if ((flags & DrawBackendTaau) != 0) return "taau";
    if ((flags & DrawBackendDlss) != 0) return "dlss";
    if ((flags & DrawBackendNoAa) != 0) return "noaa";
    return "unknown";
}

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
    wchar_t filename[176]{};
    _snwprintf_s(
        filename, _TRUNCATE,
        L"witcher3vr-smoke-visibility_%04u%02u%02u_%02u%02u%02u_%03u_%lu.log",
        local.wYear, local.wMonth, local.wDay,
        local.wHour, local.wMinute, local.wSecond, local.wMilliseconds,
        static_cast<unsigned long>(GetCurrentProcessId()));
    path = module_path;
    path += filename;
    return true;
}

bool wait_for_queue(ID3D12CommandQueue* queue) {
    if (queue == nullptr || g_device == nullptr) {
        return false;
    }
    ID3D12Fence* fence{};
    if (FAILED(g_device->CreateFence(
            0, D3D12_FENCE_FLAG_NONE, IID_PPV_ARGS(&fence))) ||
        fence == nullptr) {
        return false;
    }
    HANDLE event = CreateEventW(nullptr, FALSE, FALSE, nullptr);
    const HRESULT signal_result = event != nullptr
        ? queue->Signal(fence, 1)
        : E_FAIL;
    const HRESULT event_result = SUCCEEDED(signal_result)
        ? fence->SetEventOnCompletion(1, event)
        : E_FAIL;
    const bool completed = SUCCEEDED(event_result) &&
        WaitForSingleObject(event, 5000) == WAIT_OBJECT_0;
    if (event != nullptr) CloseHandle(event);
    fence->Release();
    return completed;
}

VisibilityCounters counters_from(
    const D3D12_QUERY_DATA_PIPELINE_STATISTICS& statistics) noexcept {
    return VisibilityCounters{
        statistics.IAPrimitives,
        statistics.VSInvocations,
        statistics.GSInvocations,
        statistics.GSPrimitives,
        statistics.CInvocations,
        statistics.CPrimitives,
        statistics.PSInvocations};
}

}  // namespace

bool initialize(ID3D12Device* device) noexcept {
    if (device == nullptr) {
        return false;
    }
    std::scoped_lock lock{g_mutex};
    if (g_initialized) {
        return g_query_heap != nullptr && g_readback != nullptr &&
            g_mapped_statistics != nullptr;
    }
    g_initialized = true;
    g_device = device;
    g_device->AddRef();

    D3D12_QUERY_HEAP_DESC query_desc{};
    query_desc.Type = D3D12_QUERY_HEAP_TYPE_PIPELINE_STATISTICS;
    query_desc.Count = kCapacity;
    if (FAILED(g_device->CreateQueryHeap(
            &query_desc, IID_PPV_ARGS(&g_query_heap))) ||
        g_query_heap == nullptr) {
        return false;
    }

    D3D12_HEAP_PROPERTIES heap{};
    heap.Type = D3D12_HEAP_TYPE_READBACK;
    D3D12_RESOURCE_DESC buffer{};
    buffer.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
    buffer.Width = static_cast<UINT64>(kCapacity) *
        sizeof(D3D12_QUERY_DATA_PIPELINE_STATISTICS);
    buffer.Height = 1;
    buffer.DepthOrArraySize = 1;
    buffer.MipLevels = 1;
    buffer.SampleDesc.Count = 1;
    buffer.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR;
    if (FAILED(g_device->CreateCommittedResource(
            &heap, D3D12_HEAP_FLAG_NONE, &buffer,
            D3D12_RESOURCE_STATE_COPY_DEST, nullptr,
            IID_PPV_ARGS(&g_readback))) ||
        g_readback == nullptr) {
        return false;
    }
    const D3D12_RANGE empty_range{0, 0};
    if (FAILED(g_readback->Map(
            0, &empty_range,
            reinterpret_cast<void**>(&g_mapped_statistics))) ||
        g_mapped_statistics == nullptr) {
        return false;
    }
    return true;
}

void update_present_clock(uint64_t present) noexcept {
    g_present.store(present, std::memory_order_relaxed);
    LARGE_INTEGER now{};
    if (QueryPerformanceCounter(&now)) {
        g_present_qpc.store(now.QuadPart, std::memory_order_relaxed);
    }
}

DrawToken begin_draw(
    ID3D12GraphicsCommandList* command_list,
    const DrawMetadata& metadata) noexcept {
    if (g_paused.load(std::memory_order_acquire)) {
        g_dropped_paused.fetch_add(1, std::memory_order_relaxed);
        return {};
    }
    const uint32_t index = g_next_sample.fetch_add(
        1, std::memory_order_relaxed);
    if (index >= kCapacity) {
        g_dropped_capacity.fetch_add(1, std::memory_order_relaxed);
        return {};
    }

    bool query_started{};
    {
        std::scoped_lock lock{g_mutex};
        auto& sample = g_samples[index];
        sample = {};
        sample.metadata = metadata;
        sample.sequence = static_cast<uint64_t>(index) + 1;
        sample.qpc = g_present_qpc.load(std::memory_order_relaxed);
        sample.thread_id = GetCurrentThreadId();
        sample.state = SampleState::Recording;
        query_started = command_list != nullptr && g_query_heap != nullptr &&
            g_readback != nullptr && g_mapped_statistics != nullptr;
        sample.query_started = query_started;
    }
    if (query_started) {
        command_list->BeginQuery(
            g_query_heap, D3D12_QUERY_TYPE_PIPELINE_STATISTICS, index);
    }
    return DrawToken{index, query_started};
}

void end_draw(
    ID3D12GraphicsCommandList* command_list,
    DrawToken token) noexcept {
    if (!token.valid() || token.index >= kCapacity) {
        return;
    }
    if (token.query_started && command_list != nullptr) {
        command_list->EndQuery(
            g_query_heap, D3D12_QUERY_TYPE_PIPELINE_STATISTICS,
            token.index);
        command_list->ResolveQueryData(
            g_query_heap, D3D12_QUERY_TYPE_PIPELINE_STATISTICS,
            token.index, 1, g_readback,
            static_cast<UINT64>(token.index) *
                sizeof(D3D12_QUERY_DATA_PIPELINE_STATISTICS));
    }
    std::scoped_lock lock{g_mutex};
    auto& sample = g_samples[token.index];
    if (sample.state != SampleState::Recording) {
        return;
    }
    sample.state = SampleState::PendingExecute;
    if (command_list != nullptr) {
        g_pending_by_command_list[command_list].push_back(token.index);
    } else {
        sample.state = SampleState::Abandoned;
    }
}

void on_execute(
    ID3D12CommandQueue* queue,
    UINT num_command_lists,
    ID3D12CommandList* const* command_lists) noexcept {
    if (queue == nullptr || command_lists == nullptr) {
        return;
    }
    std::scoped_lock lock{g_mutex};
    const uint64_t submission_serial = ++g_submission_serial;
    bool submitted_any{};
    for (UINT list_index = 0; list_index < num_command_lists; ++list_index) {
        const auto found = g_pending_by_command_list.find(
            command_lists[list_index]);
        if (found == g_pending_by_command_list.end()) {
            continue;
        }
        for (const uint32_t sample_index : found->second) {
            if (sample_index >= kCapacity) continue;
            auto& sample = g_samples[sample_index];
            if (sample.state == SampleState::PendingExecute) {
                sample.state = SampleState::Submitted;
                sample.submission_serial = submission_serial;
                submitted_any = true;
            }
        }
        g_pending_by_command_list.erase(found);
    }
    if (submitted_any && std::find(
            g_seen_queues.begin(), g_seen_queues.end(), queue) ==
            g_seen_queues.end()) {
        queue->AddRef();
        g_seen_queues.push_back(queue);
    }
}

void on_command_list_reset(
    ID3D12GraphicsCommandList* command_list) noexcept {
    if (command_list == nullptr) {
        return;
    }
    std::scoped_lock lock{g_mutex};
    const auto found = g_pending_by_command_list.find(command_list);
    if (found == g_pending_by_command_list.end()) {
        return;
    }
    for (const uint32_t sample_index : found->second) {
        if (sample_index < kCapacity &&
            g_samples[sample_index].state == SampleState::PendingExecute) {
            g_samples[sample_index].state = SampleState::Abandoned;
        }
    }
    g_pending_by_command_list.erase(found);
}

bool dump_last_seconds(
    const char* build_identity,
    uint32_t window_seconds,
    std::wstring* written_path) {
    LARGE_INTEGER now{};
    LARGE_INTEGER frequency{};
    if (!QueryPerformanceCounter(&now) ||
        !QueryPerformanceFrequency(&frequency) ||
        frequency.QuadPart <= 0) {
        return false;
    }
    g_paused.store(true, std::memory_order_release);

    uint64_t submission_cutoff{};
    std::vector<ID3D12CommandQueue*> queues{};
    {
        std::scoped_lock lock{g_mutex};
        submission_cutoff = g_submission_serial;
        queues = g_seen_queues;
        for (auto* queue : queues) {
            if (queue != nullptr) queue->AddRef();
        }
    }
    uint32_t waited_queues{};
    uint32_t failed_queues{};
    for (auto* queue : queues) {
        if (wait_for_queue(queue)) ++waited_queues;
        else ++failed_queues;
        if (queue != nullptr) queue->Release();
    }

    const int64_t minimum_qpc = now.QuadPart -
        frequency.QuadPart * static_cast<int64_t>(window_seconds);
    std::vector<DumpRow> rows{};
    {
        std::scoped_lock lock{g_mutex};
        const uint32_t sample_count = std::min(
            g_next_sample.load(std::memory_order_relaxed), kCapacity);
        rows.reserve(sample_count);
        for (uint32_t index = 0; index < sample_count; ++index) {
            const auto& sample = g_samples[index];
            if (sample.qpc < minimum_qpc ||
                sample.state == SampleState::Empty ||
                sample.state == SampleState::Recording) {
                continue;
            }
            DumpRow row{};
            row.sample = sample;
            row.gpu_ready = failed_queues == 0 && sample.query_started &&
                sample.state == SampleState::Submitted &&
                sample.submission_serial != 0 &&
                sample.submission_serial <= submission_cutoff &&
                g_mapped_statistics != nullptr;
            if (row.gpu_ready) {
                row.statistics = g_mapped_statistics[index];
            }
            rows.push_back(row);
        }
    }
    g_paused.store(false, std::memory_order_release);

    std::wstring path{};
    if (!build_dump_path(path)) {
        return false;
    }
    FILE* file{};
    if (_wfopen_s(&file, path.c_str(), L"w") != 0 || file == nullptr) {
        return false;
    }

    fprintf(file,
        "# Witcher3VR smoke visibility recorder build=%s window=%us hotkey=F3\n",
        build_identity != nullptr ? build_identity : "unknown",
        window_seconds);
    fprintf(file,
        "# exact canonical smoke draws only; rendering inputs are observed but never changed by this recorder\n");
    fprintf(file,
        "# rows=%zu claimed=%u capacity=%u dropped_capacity=%llu dropped_paused=%llu queues_waited=%u queues_failed=%u submission_cutoff=%llu\n",
        rows.size(), g_next_sample.load(std::memory_order_relaxed), kCapacity,
        static_cast<unsigned long long>(
            g_dropped_capacity.load(std::memory_order_relaxed)),
        static_cast<unsigned long long>(
            g_dropped_paused.load(std::memory_order_relaxed)),
        waited_queues, failed_queues,
        static_cast<unsigned long long>(submission_cutoff));
    fprintf(file,
        "# diagnosis: visible=PS ran; clip_or_cull_zero=GS emitted but clipper produced zero; pixel_zero=clipper survived but PS ran zero times\n");

    std::array<uint64_t, 7> diagnosis_counts{};
    for (const auto& row : rows) {
        const bool geometry_shader_expected =
            row.sample.metadata.variant_index >= 0;
        const auto diagnosis = diagnose_visibility(
            counters_from(row.statistics), row.gpu_ready,
            geometry_shader_expected);
        ++diagnosis_counts[static_cast<size_t>(diagnosis)];
    }
    fprintf(file, "# summary");
    for (size_t index = 0; index < diagnosis_counts.size(); ++index) {
        fprintf(file, " %s=%llu",
            visibility_diagnosis_name(
                static_cast<VisibilityDiagnosis>(index)),
            static_cast<unsigned long long>(diagnosis_counts[index]));
    }
    fprintf(file, "\n");

    for (const auto& row : rows) {
        const auto& metadata = row.sample.metadata;
        const auto counters = counters_from(row.statistics);
        const auto diagnosis = diagnose_visibility(
            counters, row.gpu_ready, metadata.variant_index >= 0);
        const double milliseconds = static_cast<double>(
            row.sample.qpc - now.QuadPart) * 1000.0 /
            static_cast<double>(frequency.QuadPart);
        fprintf(file,
            "%10.3f seq=%llu p=%llu route=%s backend=%s projection=%s eye=%d pair=%llu gen=%u authority=%u variant=%d flags=0x%08X diagnosis=%s gpu=%u tid=%u cmd=%p pso=%p->%p draw=%u,%u,%u,%d,%u raster=%u,%u,%u viewport=%u:%.3f,%.3f,%.3f,%.3f,%.3f,%.3f scissor=%u:%ld,%ld,%ld,%ld tables=0x%llX,0x%llX b1=%u:0x%llX camera=%.6f,%.6f,%.6f clip=%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f stats=%llu,%llu,%llu,%llu,%llu,%llu,%llu\n",
            milliseconds,
            static_cast<unsigned long long>(row.sample.sequence),
            static_cast<unsigned long long>(metadata.present),
            route_name(metadata.flags), backend_name(metadata.flags),
            projection_name(metadata.pixel_projection), metadata.eye,
            static_cast<unsigned long long>(metadata.pair_id),
            metadata.generation, metadata.authority_route,
            metadata.variant_index, metadata.flags,
            visibility_diagnosis_name(diagnosis), row.gpu_ready ? 1u : 0u,
            row.sample.thread_id,
            reinterpret_cast<void*>(metadata.command_list),
            reinterpret_cast<void*>(metadata.original_pipeline),
            reinterpret_cast<void*>(metadata.selected_pipeline),
            metadata.index_count, metadata.instance_count,
            metadata.start_index, metadata.base_vertex,
            metadata.start_instance, metadata.cull_mode,
            metadata.front_counter_clockwise,
            metadata.depth_clip_enable, metadata.viewport_count,
            metadata.viewport.TopLeftX, metadata.viewport.TopLeftY,
            metadata.viewport.Width, metadata.viewport.Height,
            metadata.viewport.MinDepth, metadata.viewport.MaxDepth,
            metadata.scissor_count,
            metadata.scissor.left, metadata.scissor.top,
            metadata.scissor.right, metadata.scissor.bottom,
            static_cast<unsigned long long>(metadata.root3_table),
            static_cast<unsigned long long>(metadata.root6_table),
            (metadata.flags & DrawB1Captured) != 0 ? 1u : 0u,
            static_cast<unsigned long long>(metadata.b1_hash),
            metadata.camera_position[0], metadata.camera_position[1],
            metadata.camera_position[2],
            metadata.clip_matrix[0], metadata.clip_matrix[1],
            metadata.clip_matrix[4], metadata.clip_matrix[5],
            metadata.clip_matrix[8], metadata.clip_matrix[9],
            metadata.clip_matrix[12], metadata.clip_matrix[13],
            static_cast<unsigned long long>(counters.input_primitives),
            static_cast<unsigned long long>(counters.vertex_invocations),
            static_cast<unsigned long long>(counters.geometry_invocations),
            static_cast<unsigned long long>(counters.geometry_primitives),
            static_cast<unsigned long long>(counters.clipper_invocations),
            static_cast<unsigned long long>(counters.clipper_primitives),
            static_cast<unsigned long long>(counters.pixel_invocations));
    }
    fclose(file);
    if (written_path != nullptr) {
        *written_path = path;
    }
    OutputDebugStringW(L"Witcher3VR smoke visibility recorder dumped by F3\n");
    return true;
}

}  // namespace w3vr::smoke_visibility
