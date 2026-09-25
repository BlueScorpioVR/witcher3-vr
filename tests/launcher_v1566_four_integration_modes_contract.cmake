if(NOT DEFINED SOURCE_ROOT)
    message(FATAL_ERROR "SOURCE_ROOT is required")
endif()

file(READ "${SOURCE_ROOT}/launcher/main.cpp" main)
file(READ "${SOURCE_ROOT}/launcher/config.cpp" config)
file(READ "${SOURCE_ROOT}/launcher/config.h" header)
file(READ "${SOURCE_ROOT}/launcher/managed_runtime.cpp" managed)
file(READ "${SOURCE_ROOT}/launcher/witcher3vr.default.ini" defaults)
file(READ "${SOURCE_ROOT}/scripts/package-release.ps1" package)

foreach(required IN ITEMS
        "IdHudControllerLocked"
        "Controller-locked HUD (Experimental)"
        "IntegrationModeUsesOptiscaler(state.integration_mode)"
        "FSR 3.1 VR Framegen requires a DLSS render mode")
    string(FIND "${main}" "${required}" found)
    if(found EQUAL -1)
        message(FATAL_ERROR "Missing V1566 launcher control: ${required}")
    endif()
endforeach()

foreach(required IN ITEMS
        "L\"Off\""
        "L\"OptiScaler\""
        "L\"ReShade\""
        "L\"OptiScaler + ReShade\""
        "if (value == \"optiscaler_dlss5\") return IntegrationMode::Optiscaler"
        "vr_ini.Set(\"openxr\", \"hud_controller_locked\"")
    string(FIND "${config}" "${required}" found)
    if(found EQUAL -1)
        message(FATAL_ERROR "Missing V1566 mode or INI contract: ${required}")
    endif()
endforeach()

foreach(required IN ITEMS
        "OptiscalerReshade,"
        "Count,"
        "bool hud_controller_locked{};")
    string(FIND "${header}" "${required}" found)
    if(found EQUAL -1)
        message(FATAL_ERROR "Missing V1566 state: ${required}")
    endif()
endforeach()

foreach(required IN ITEMS
        "witcher3vr-optiscaler-dlss5-reference"
        "L\"nvngx_dlssnr.dll\""
        "if (use_optiscaler)"
        "!RemoveFileIfPresent(root / L\"OptiScaler.dll\", error)"
        "CleanupLegacyOptiscalerPayload")
    string(FIND "${managed}" "${required}" found)
    if(found EQUAL -1)
        message(FATAL_ERROR "Missing V1566 runtime composition: ${required}")
    endif()
endforeach()

foreach(forbidden IN ITEMS
        "OptiscalerDlss5,"
        "kCanonicalOptiscalerFiles"
        "ConfigurePersistentReshade"
        "SetCsvToken"
        "nvngx_dlssg.dll"
        "L\"nvngx_dlss.dll\"")
    string(FIND "${main}${config}${header}${managed}" "${forbidden}" found)
    if(NOT found EQUAL -1)
        message(FATAL_ERROR "Retired V1566 route remains: ${forbidden}")
    endif()
endforeach()

string(FIND "${package}" "witcher3vr-optiscaler-reference" old_reference)
if(NOT old_reference EQUAL -1)
    message(FATAL_ERROR "Package still includes retired OptiScaler reference")
endif()
string(FIND "${package}" "Put nvngx_dlssnr.dll" nr_instruction)
if(nr_instruction EQUAL -1)
    message(FATAL_ERROR "Package must require only NVIDIA NR")
endif()
string(FIND "${defaults}" "hud_controller_locked=0" hud_default)
if(hud_default EQUAL -1)
    message(FATAL_ERROR "Controller-locked HUD must default off")
endif()
