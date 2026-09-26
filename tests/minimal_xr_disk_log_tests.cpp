#include "minimal_xr_disk_log.h"
#include <string>

int main(int argc, char**) {
    w3vr::minimal_xr_log::initialize(false);
    w3vr::minimal_xr_log::write("OFF");
    w3vr::minimal_xr_log::hud("OFF", "%d", 1);
    if (w3vr::minimal_xr_log::file != INVALID_HANDLE_VALUE) return 10;
    if (argc > 1) {
        w3vr::minimal_xr_log::initialize(true);
        w3vr::minimal_xr_log::write("CRASH_SENTINEL", 42, 7, 99, -3);
        w3vr::minimal_xr_log::hud("TEST", "present=%llu slot=%u serial=%llu reason=%s", 42ull, 2u, 99ull, "pending");
        w3vr::minimal_xr_log::initialize(false);
        w3vr::minimal_xr_log::write("OFF_AFTER_ON");
        // No cleanup, CloseHandle, C runtime exit or manual dump.
        TerminateProcess(GetCurrentProcess(), 73);
        return 9;
    }
    wchar_t exe[32768]{};
    GetModuleFileNameW(nullptr, exe, 32768);
    std::wstring command = L"\"" + std::wstring(exe) + L"\" child";
    STARTUPINFOW startup{sizeof(startup)};
    PROCESS_INFORMATION process{};
    if (!CreateProcessW(nullptr, command.data(), nullptr, nullptr, FALSE, 0,
                        nullptr, nullptr, &startup, &process)) return 1;
    if (WaitForSingleObject(process.hProcess, 10000) != WAIT_OBJECT_0) {
        TerminateProcess(process.hProcess, 74);
        return 2;
    }
    DWORD code{};
    GetExitCodeProcess(process.hProcess, &code);
    CloseHandle(process.hThread);
    CloseHandle(process.hProcess);
    if (code != 73) return 3;
    std::wstring directory(exe);
    directory.resize(directory.find_last_of(L'\\') + 1);
    const std::wstring pattern = directory + L"witcher3vr-minimal-V1550-*-" +
        std::to_wstring(process.dwProcessId) + L".log";
    WIN32_FIND_DATAW found{};
    HANDLE search = FindFirstFileW(pattern.c_str(), &found);
    if (search == INVALID_HANDLE_VALUE) return 4;
    FindClose(search);
    const auto path = directory + found.cFileName;
    HANDLE input = CreateFileW(path.c_str(), GENERIC_READ, FILE_SHARE_READ | FILE_SHARE_WRITE,
                              nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
    char bytes[1024]{};
    DWORD count{};
    const bool read = ReadFile(input, bytes, sizeof(bytes) - 1, &count, nullptr) != FALSE;
    CloseHandle(input);
    const std::string contents(bytes, count);
    const bool valid = read && contents.find("OFF") == std::string::npos && contents.find("V1550_START_") != std::string::npos &&
        contents.find("CRASH_SENTINEL 42 7 99 -3\r\n") != std::string::npos &&
        contents.find("HUD_TEST present=42 slot=2 serial=99 reason=pending\r\n") != std::string::npos;
    // Remove only the file belonging to this test's child PID.
    DeleteFileW(path.c_str());
    return valid ? 0 : 5;
}
