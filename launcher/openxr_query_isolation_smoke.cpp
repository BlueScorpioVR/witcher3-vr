#include "openxr_resolution.h"

#include <Windows.h>

#include <array>
#include <filesystem>
#include <iostream>
#include <string>

namespace fs = std::filesystem;

namespace {

bool IsWithin(const fs::path& candidate, const fs::path& directory) {
    const auto normalized_candidate = candidate.lexically_normal().wstring();
    auto normalized_directory = directory.lexically_normal().wstring();
    if (!normalized_directory.empty() && normalized_directory.back() != L'\\') {
        normalized_directory.push_back(L'\\');
    }
    return normalized_candidate.size() > normalized_directory.size() &&
        _wcsnicmp(normalized_candidate.c_str(), normalized_directory.c_str(),
            normalized_directory.size()) == 0;
}

} // namespace

int wmain(int argc, wchar_t** argv) {
    if (argc != 2) {
        std::wcerr << L"usage: smoke <directory containing openxr_loader.dll>\n";
        return 2;
    }

    wchar_t executable_path[32768]{};
    const DWORD executable_length = GetModuleFileNameW(
        nullptr, executable_path,
        static_cast<DWORD>(std::size(executable_path)));
    if (executable_length == 0 ||
        executable_length >= std::size(executable_path)) {
        std::wcerr << L"could not resolve smoke-test executable directory\n";
        return 2;
    }
    const fs::path executable_directory =
        fs::path(executable_path).parent_path();

    w3vr::OpenXrRecommendedResolution resolution{};
    std::wstring query_error;
    const bool query_ok = w3vr::QueryOpenXrRecommendedResolution(
        fs::path(argv[1]), resolution, query_error);

    constexpr auto managed_modules = std::to_array<const wchar_t*>({
        L"dxgi.dll", L"OptiScaler.dll", L"ReShade64.dll",
        L"nvngx_dlss.dll", L"nvngx_dlssg.dll", L"nvngx_dlssnr.dll",
        L"nvngx.dll_dlssnr.dll"});
    bool local_managed_module_loaded{};
    for (const auto* name : managed_modules) {
        const HMODULE module = GetModuleHandleW(name);
        if (module == nullptr) continue;
        wchar_t module_path[32768]{};
        const DWORD module_length = GetModuleFileNameW(
            module, module_path, static_cast<DWORD>(std::size(module_path)));
        if (module_length != 0 && module_length < std::size(module_path) &&
            IsWithin(fs::path(module_path), executable_directory)) {
            std::wcerr << L"managed module loaded from query directory: "
                       << module_path << L'\n';
            local_managed_module_loaded = true;
        }
    }

    if (!query_ok) {
        std::wcerr << L"OpenXR query failed: " << query_error << L'\n';
    } else {
        std::wcout << L"OpenXR query returned " << resolution.width << L'x'
                   << resolution.height << L'\n';
    }
    return local_managed_module_loaded ? 1 : (query_ok ? 0 : 2);
}
