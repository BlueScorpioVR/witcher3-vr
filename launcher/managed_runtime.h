#pragma once

#include <filesystem>
#include <string>

#include "config.h"

namespace w3vr {

bool ApplyManagedIntegrationMode(
    const std::filesystem::path& dx12_directory,
    IntegrationMode desired,
    std::wstring& error);

} // namespace w3vr
