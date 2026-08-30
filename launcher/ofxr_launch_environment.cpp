#include "ofxr_launch_environment.h"

#include <Windows.h>

#include <algorithm>
#include <array>
#include <string_view>

namespace w3vr {
namespace {

bool ManagedEntry(std::wstring_view entry) {
    constexpr std::array<std::wstring_view, 3> names{
        L"XR_API_LAYER_PATH",
        L"XR_ENABLE_API_LAYERS",
        L"XRFG_FLOW_BACKEND",
    };
    const size_t search_start = !entry.empty() && entry.front() == L'=' ? 1 : 0;
    const size_t separator = entry.find(L'=', search_start);
    if (separator == std::wstring_view::npos) return false;
    const std::wstring_view name = entry.substr(0, separator);
    return std::any_of(names.begin(), names.end(),
        [name](std::wstring_view candidate) {
            return name.size() == candidate.size() &&
                _wcsnicmp(name.data(), candidate.data(), name.size()) == 0;
        });
}

} // namespace

bool RemoveRetiredOfxrPayload(
    const std::filesystem::path& launcher_directory,
    std::wstring& error) {
    // [FIX:OFXR-ROOT-LAYOUT V1510 2/3] The launcher is the only injector.
    // Physically remove the retired tray executable and subfolder package so
    // they cannot register or load a second copy of the API layer.
    const auto legacy_directory = launcher_directory / L"ofxr";
    const auto legacy_tray = launcher_directory / L"OFXRBridgeTray.exe";
    std::error_code cleanup_error;
    std::filesystem::remove_all(legacy_directory, cleanup_error);
    if (cleanup_error) {
        error = L"Could not remove the retired OFXR folder:\n" +
            legacy_directory.wstring() + L"\n\nWindows error " +
            std::to_wstring(cleanup_error.value()) + L". Close OFXR Bridge "
            L"and try again.";
        return false;
    }
    std::filesystem::remove(legacy_tray, cleanup_error);
    if (cleanup_error) {
        error = L"Could not remove the retired OFXR Bridge executable:\n" +
            legacy_tray.wstring() + L"\n\nWindows error " +
            std::to_wstring(cleanup_error.value()) + L". Close OFXR Bridge "
            L"and try again.";
        return false;
    }
    return true;
}

bool BuildEnabledOfxrLaunchEnvironment(
    const std::filesystem::path& launcher_directory,
    FrameGenerationBackend backend,
    std::vector<wchar_t>& block,
    std::wstring& error) {
    block.clear();
    // [FIX:OFXR-OFF-OLD-LAUNCH V1498 1/2] Off never enters the OFXR launch
    // path. Reject it here as a contract violation instead of keeping an
    // empty-environment fallback inside the injector helper.
    if (backend == FrameGenerationBackend::Off) {
        error = L"OFXR launch environment requested while Frame Generation is Off.";
        return false;
    }

    // [FIX:OFXR-ROOT-LAYOUT V1510 1/3] XRFG-V040 resolves its configuration
    // beside the loaded API-layer DLL. Keep the manifest, DLL and INI beside
    // the launcher so one root of the game owns both configuration and launch.
    const auto layer_directory = launcher_directory;
    constexpr std::array<const wchar_t*, 3> required_files{
        L"XR_APILAYER_XRFrameBridge_diagnostic.dll",
        L"XR_APILAYER_XRFrameBridge_diagnostic.json",
        L"ofxr_bridge.ini",
    };
    for (const wchar_t* file : required_files) {
        const auto path = layer_directory / file;
        const DWORD attributes = GetFileAttributesW(path.c_str());
        if (attributes == INVALID_FILE_ATTRIBUTES ||
            (attributes & FILE_ATTRIBUTE_DIRECTORY) != 0) {
            error = L"OFXR Bridge is selected, but this file is missing:\n" +
                path.wstring() +
                L"\n\nInstall the XRFG-V040 bridge files beside the launcher, "
                L"or select Off.";
            return false;
        }
    }

    LPWCH inherited = GetEnvironmentStringsW();
    if (inherited == nullptr) {
        error = L"Could not read the current process environment (Windows error " +
            std::to_wstring(GetLastError()) + L").";
        return false;
    }
    std::vector<std::wstring> entries;
    for (const wchar_t* cursor = inherited; *cursor != L'\0';) {
        const std::wstring_view entry(cursor);
        if (!ManagedEntry(entry)) {
            entries.emplace_back(entry);
        }
        cursor += entry.size() + 1;
    }
    FreeEnvironmentStringsW(inherited);

    entries.push_back(L"XR_API_LAYER_PATH=" + layer_directory.wstring());
    entries.emplace_back(
        L"XR_ENABLE_API_LAYERS=XR_APILAYER_XRFrameBridge_diagnostic");
    // XRFG-V040 reads [ofxr] backend from the root ofxr_bridge.ini. The
    // obsolete XRFG_FLOW_BACKEND variable is deliberately scrubbed from the
    // inherited environment by ManagedEntry and is never recreated here.
    std::sort(entries.begin(), entries.end(),
        [](const std::wstring& left, const std::wstring& right) {
            return _wcsicmp(left.c_str(), right.c_str()) < 0;
        });

    size_t character_count = 1;
    for (const std::wstring& entry : entries) {
        character_count += entry.size() + 1;
    }
    block.reserve(character_count);
    for (const std::wstring& entry : entries) {
        block.insert(block.end(), entry.begin(), entry.end());
        block.push_back(L'\0');
    }
    block.push_back(L'\0');
    return true;
}

} // namespace w3vr
