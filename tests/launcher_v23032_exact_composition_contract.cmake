if(NOT DEFINED SOURCE_ROOT)
    message(FATAL_ERROR "SOURCE_ROOT is required")
endif()

file(READ "${SOURCE_ROOT}/launcher/main.cpp" main)
file(READ "${SOURCE_ROOT}/launcher/config.cpp" config)
file(READ "${SOURCE_ROOT}/launcher/config.h" header)
file(READ "${SOURCE_ROOT}/launcher/managed_runtime.cpp" managed)
file(READ "${SOURCE_ROOT}/launcher/managed_runtime.h" managed_header)
file(READ "${SOURCE_ROOT}/launcher/openxr_resolution.cpp" openxr_query)
file(READ "${SOURCE_ROOT}/launcher/witcher3vr.default.ini" defaults)
file(READ "${SOURCE_ROOT}/scripts/package-release.ps1" package)

foreach(required IN ITEMS
        "enum class IntegrationMode"
        "Off,"
        "Optiscaler,"
        "Reshade,"
        "OptiscalerReshade,"
        "OptiscalerDlss5,"
        "ReshadeDlss5,"
        "ReshadeDlss5Cheeky,"
        "IntegrationMode integration_mode{IntegrationMode::Off};")
    string(FIND "${header}" "${required}" found)
    if(found EQUAL -1)
        message(FATAL_ERROR "Missing six-mode integration contract: ${required}")
    endif()
endforeach()

foreach(required IN ITEMS
        "L\"Off\""
        "L\"OptiScaler\""
        "L\"ReShade\""
        "L\"OptiScaler + ReShade\""
        "L\"OptiScaler DLSS5\""
        "L\"ReShade DLSS5 RenoDX\""
        "L\"ReShade DLSS5 Cheeky\""
        "integration_mode=off")
    string(FIND "${config}${defaults}" "${required}" found)
    if(found EQUAL -1)
        message(FATAL_ERROR "Missing six-mode persistence/default: ${required}")
    endif()
endforeach()

foreach(required IN ITEMS
        "Witcher 3 VR Launcher - V"
        "IdIntegrationMode"
        "ApplyManagedIntegrationMode"
        "state.integration_mode")
    string(FIND "${main}" "${required}" found)
    if(found EQUAL -1)
        message(FATAL_ERROR "Missing V23032 integration UI: ${required}")
    endif()
endforeach()

foreach(required IN ITEMS
        "witcher3vr-mod-reference"
        "witcher3vr-reshade-reference"
        "witcher3vr-reshade-dlss5-reference"
        "witcher3vr-optiscaler-reference"
        "witcher3vr-optiscaler-dlss5-reference"
        "witcher3vr-dlss5-reference"
        "ValidateDlss5Reference"
        "kCanonicalOptiscalerFiles"
        "kDlss5OptiscalerFiles"
        "ReShade64.dll"
        "ProxyLibrary"
        "LoadFromDllMain"
        "ApplyManagedIntegrationMode")
    string(FIND "${managed}" "${required}" found)
    if(found EQUAL -1)
        message(FATAL_ERROR "Missing reference switch contract: ${required}")
    endif()
endforeach()

foreach(forbidden IN ITEMS
        "witcher3vr-managed"
        "MoveManagedFile(reference"
        "RemoveFileIfPresent(reference"
        "ApplyManagedRuntimeState"
        "ManagedRuntimeState")
    string(FIND "${managed}${managed_header}${package}" "${forbidden}" found)
    if(NOT found EQUAL -1)
        message(FATAL_ERROR "Superseded managed-state path remains: ${forbidden}")
    endif()
endforeach()

foreach(required IN ITEMS
        "witcher3vr-mod-reference"
        "witcher3vr-reshade-reference"
        "witcher3vr-reshade-dlss5-reference"
        "witcher3vr-optiscaler-reference"
        "witcher3vr-optiscaler-dlss5-reference"
        "witcher3vr-dlss5-reference"
        "DLSS5 files are not bundled.")
    string(FIND "${package}" "${required}" found)
    if(found EQUAL -1)
        message(FATAL_ERROR "Missing V23032 package layout: ${required}")
    endif()
endforeach()

string(FIND "${package}"
    "runtime/witcher3vr-dlss5-reference" bundled_reference)
if(NOT bundled_reference EQUAL -1)
    message(FATAL_ERROR "Public package reads the private DLSS5 reference")
endif()

foreach(required IN ITEMS
        "RENDERER-FIRST-INTEGRATION-SWITCH V23024"
        "operations.push_back({mod_reference / L\"dxgi.dll\""
        "root / L\"dxgi.dll\""
        "root / kReshadeRuntime"
        "EnableProxyLibrary\", \"0\"")
    string(FIND "${managed}" "${required}" found)
    if(found EQUAL -1)
        message(FATAL_ERROR "Missing renderer-first chain: ${required}")
    endif()
endforeach()

foreach(required IN ITEMS
        "IDEMPOTENT-RUNTIME-CLEANUP V23025"
        ".w3vr-v23032-next"
        "LEAN-DLSS5-REFERENCE V23031"
        "EXACT-INTEGRATION-COMPOSITION V23032"
        "CleanupLegacyOptiscalerPayload"
        "RemoveFileIfPresent(root / L\"nvngx.dll_dlssnr.dll\"")
    string(FIND "${managed}" "${required}" found)
    if(found EQUAL -1)
        message(FATAL_ERROR "Missing V23032 exact-composition contract: ${required}")
    endif()
endforeach()

string(REGEX MATCHALL "IsNotFound\\(code\\)\\) return true" not_found_guards
    "${managed}")
list(LENGTH not_found_guards not_found_guard_count)
if(not_found_guard_count LESS 2)
    message(FATAL_ERROR "V23032 must tolerate not-found races in every shared cleanup phase")
endif()

foreach(stale_suffix IN ITEMS
        ".w3vr-v23025-next"
        ".w3vr-v23026-next"
        ".w3vr-v23031-next")
    string(FIND "${managed}" "${stale_suffix}" stale_temporary_suffix)
    if(NOT stale_temporary_suffix EQUAL -1)
        message(FATAL_ERROR "V23032 still uses superseded staging suffix: ${stale_suffix}")
    endif()
endforeach()

foreach(required IN ITEMS
        "OPENXR-QUERY-SYSTEM-DXGI V23026"
        "GetSystemDirectoryW"
        "GetModuleHandleW(L\"dxgi.dll\")"
        "LoadLibraryW(system_dxgi_path.c_str())")
    string(FIND "${openxr_query}" "${required}" found)
    if(found EQUAL -1)
        message(FATAL_ERROR "Missing inherited OpenXR query isolation: ${required}")
    endif()
endforeach()

string(FIND "${openxr_query}" "LoadLibraryW(L\"dxgi.dll\")" unsafe_dxgi_load)
if(NOT unsafe_dxgi_load EQUAL -1)
    message(FATAL_ERROR "OpenXR query can still resolve the game-root DXGI proxy")
endif()

message(STATUS "V23032 exact composition, cleanup and OpenXR query isolation verified")
