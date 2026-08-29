#pragma once

#include "config.h"

#include <filesystem>
#include <string>
#include <string_view>
#include <vector>

namespace w3vr {

bool IsWindowsHdrActive();
bool IsRivaTunerStatisticsServerRunning();

bool IsKnownDx12Dll(std::wstring_view filename);
std::vector<std::wstring> FindForeignDx12Dlls(
    const std::filesystem::path& dx12_directory);
std::string ForeignDllWarningSignature(
    const std::vector<std::wstring>& filenames);
bool IsForeignDllWarningSuppressed(
    const ConfigPaths& paths, const std::string& signature);
bool SuppressForeignDllWarning(
    const ConfigPaths& paths, const std::string& signature,
    std::wstring& error);

} // namespace w3vr
