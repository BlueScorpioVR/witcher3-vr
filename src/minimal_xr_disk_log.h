#pragma once
#include <Windows.h>
#include <cstdint>
#include <cstdio>

// V1539 trial-only breadcrumbs. Independent of all renderer diagnostic gates.
// One WriteFile per event, no CRT file buffering, flush, worker, GPU query or lock.
// The OS cache survives process termination, not power loss or an OS failure.
namespace w3vr::minimal_xr_log {
inline HANDLE file = INVALID_HANDLE_VALUE;
inline void write(const char* event, uint64_t frame = 0, uint64_t pair = 0,
                  uint64_t fence = 0, int64_t result = 0) noexcept {
    if (file == INVALID_HANDLE_VALUE) return;
    LARGE_INTEGER now{};
    QueryPerformanceCounter(&now);
    char line[192];
    const int size = snprintf(line, sizeof(line), "%lld %lu %s %llu %llu %llu %lld\r\n",
        now.QuadPart, GetCurrentThreadId(), event,
        static_cast<unsigned long long>(frame), static_cast<unsigned long long>(pair),
        static_cast<unsigned long long>(fence), static_cast<long long>(result));
    if (size <= 0 || size >= sizeof(line)) return;
    DWORD written{};
    WriteFile(file, line, static_cast<DWORD>(size), &written, nullptr);
}
inline void initialize() noexcept {
    wchar_t path[32768]{};
    const DWORD length = GetModuleFileNameW(nullptr, path, 32768);
    if (!length || length >= 32768) return;
    wchar_t* name = wcsrchr(path, L'\\');
    if (!name) return;
    ++name;
    SYSTEMTIME utc{};
    GetSystemTime(&utc);
    swprintf_s(name, 32768 - (name - path),
        L"witcher3vr-minimal-V1539-%04u%02u%02u-%02u%02u%02u-%lu.log",
        utc.wYear, utc.wMonth, utc.wDay, utc.wHour, utc.wMinute, utc.wSecond,
        GetCurrentProcessId());
    file = CreateFileW(path, FILE_APPEND_DATA, FILE_SHARE_READ | FILE_SHARE_WRITE,
        nullptr, CREATE_NEW, FILE_ATTRIBUTE_NORMAL, nullptr);
    LARGE_INTEGER frequency{};
    QueryPerformanceFrequency(&frequency);
    write("V1539_START_qpc_tid_event_frame_pair_fence_result", 0, 0, 0, frequency.QuadPart);
    // Process-lifetime handle: no teardown race with a renderer callback.
}
}
