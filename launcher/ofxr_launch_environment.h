#pragma once

#include "config.h"

#include <filesystem>
#include <string>
#include <vector>

namespace w3vr {

bool BuildEnabledOfxrLaunchEnvironment(
    const std::filesystem::path& launcher_directory,
    FrameGenerationBackend backend,
    std::vector<wchar_t>& block,
    std::wstring& error);

} // namespace w3vr
