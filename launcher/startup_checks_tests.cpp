#include "startup_checks.h"

#include <Windows.h>

#include <filesystem>
#include <fstream>
#include <iostream>
#include <stdexcept>

namespace {

void Require(bool condition, const char* message) {
    if (!condition) throw std::runtime_error(message);
}

void Touch(const std::filesystem::path& path) {
    std::ofstream output(path, std::ios::binary | std::ios::trunc);
    output << 'x';
}

} // namespace

int wmain() {
    try {
        const auto root = std::filesystem::temp_directory_path() /
            (L"w3vr-startup-checks-" + std::to_wstring(GetCurrentProcessId()));
        std::filesystem::remove_all(root);
        std::filesystem::create_directories(root);

        Touch(root / L"steam_api64.dll");
        Touch(root / L"DXGI.DLL");
        Touch(root / L"OptiScaler.dll");
        Touch(root / L"renderdoc.dll");
        Touch(root / L"ReShade64.dll");
        Touch(root / L"d3d12.dll");
        Touch(root / L"not-a-library.txt");

        const auto foreign = w3vr::FindForeignDx12Dlls(root);
        Require(foreign.size() == 2,
            "foreign DLL scan did not exclude game/mod-owned DLLs");
        Require(foreign[0] == L"d3d12.dll" &&
                foreign[1] == L"ReShade64.dll",
            "foreign DLL scan did not return the expected sorted names");
        Require(w3vr::IsKnownDx12Dll(L"NvNgX_DlSs.DlL"),
            "known DLL matching is not case-insensitive");
        Require(!w3vr::IsKnownDx12Dll(L"version.dll"),
            "foreign proxy DLL was incorrectly allowlisted");

        const auto forward = w3vr::ForeignDllWarningSignature(foreign);
        const auto reversed = w3vr::ForeignDllWarningSignature(
            {L"RESHade64.DLL", L"D3D12.DLL"});
        Require(!forward.empty() && forward == reversed,
            "foreign DLL signature is not stable and order-insensitive");

        const w3vr::ConfigPaths paths{
            root, root / L"witcher3vr.ini", root / L"optiscaler_bridge.ini",
            root / L"ofxr_bridge.ini", root / L"dx12user.settings",
            root / L"witcher3.exe"};
        {
            std::ofstream ini(paths.vr_ini, std::ios::binary | std::ios::trunc);
            ini << "[meta]\r\nconfig_version=16\r\n";
        }
        Require(!w3vr::IsForeignDllWarningSuppressed(paths, forward),
            "fresh foreign DLL warning was unexpectedly suppressed");
        std::wstring error;
        Require(w3vr::SuppressForeignDllWarning(paths, forward, error),
            "foreign DLL warning suppression could not be saved");
        Require(w3vr::IsForeignDllWarningSuppressed(paths, forward),
            "saved foreign DLL warning signature was not recognized");
        Require(!w3vr::IsForeignDllWarningSuppressed(paths, forward + "1"),
            "a changed foreign DLL set did not restore the warning");

        std::filesystem::remove_all(root);
        std::cout << "startup checks passed\n";
        return 0;
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}
