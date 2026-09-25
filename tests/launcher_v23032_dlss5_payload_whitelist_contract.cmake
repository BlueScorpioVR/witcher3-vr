if(NOT DEFINED SOURCE_ROOT)
    message(FATAL_ERROR "SOURCE_ROOT is required")
endif()

file(READ "${SOURCE_ROOT}/launcher/main.cpp" launcher_source)
file(READ "${SOURCE_ROOT}/launcher/managed_runtime.cpp" runtime_source)
file(READ "${SOURCE_ROOT}/launcher/startup_checks.cpp" startup_source)
file(READ "${SOURCE_ROOT}/launcher/startup_checks_tests.cpp" startup_tests)

foreach(required IN ITEMS
        "Witcher 3 VR Launcher - V"
        "F4 ReShade"
        "DEL OptiScaler"
        "Page Up FPS"
        "Page Down FPS view"
        "End Frame Generation")
    string(FIND "${launcher_source}" "${required}" position)
    if(position EQUAL -1)
        message(FATAL_ERROR "Missing V23032 visible binding: ${required}")
    endif()
endforeach()

foreach(required IN ITEMS
        "RENDERER-FIRST-INTEGRATION-SWITCH V23024"
        "LEAN-DLSS5-REFERENCE V23031"
        "EXACT-INTEGRATION-COMPOSITION V23032"
        "KeyOverlay\", \"115,0,0,0"
        "kDlss5Files"
        "nvngx_dlss.dll"
        "nvngx_dlssg.dll"
        "nvngx_dlssnr.dll")
    string(FIND "${runtime_source}" "${required}" position)
    if(position EQUAL -1)
        message(FATAL_ERROR "Missing V23032 runtime safety contract: ${required}")
    endif()
endforeach()

foreach(required IN ITEMS
        "DLSS5-RUNTIME-WHITELIST V23024"
        "nvngx.dll_dlssnr.dll")
    string(FIND "${startup_source}" "${required}" position)
    if(position EQUAL -1)
        message(FATAL_ERROR "Missing inherited startup allowlist entry: ${required}")
    endif()
    if(NOT required STREQUAL "DLSS5-RUNTIME-WHITELIST V23024")
        string(FIND "${startup_tests}" "${required}" test_position)
        if(test_position EQUAL -1)
            message(FATAL_ERROR "Missing startup allowlist fixture: ${required}")
        endif()
    endif()
endforeach()

# Binary fixtures are optional for source-only clones; when staged, verify them.
if(NOT EXISTS "${SOURCE_ROOT}/runtime")
    message(STATUS "Source allowlist verified; runtime payload is not staged")
    return()
endif()

set(modified_reference
    "${SOURCE_ROOT}/runtime/witcher3vr-optiscaler-dlss5-reference")
file(GLOB modified_entries RELATIVE "${modified_reference}"
    "${modified_reference}/*")
list(SORT modified_entries)
set(expected_modified_entries OptiScaler.dll nvngx.dll_dlssnr.dll
    amd_fidelityfx_framegeneration_dx12.dll
    ofxr_amd_fidelityfx_framegeneration_dx12.dll)
list(SORT expected_modified_entries)
if(NOT modified_entries STREQUAL expected_modified_entries)
    message(FATAL_ERROR "Modified OptiScaler reference must contain exactly the V23073 DLL, forwarder and two FSR runtime aliases")
endif()

file(SIZE "${modified_reference}/OptiScaler.dll" modified_dll_size)
if(modified_dll_size LESS 1000000)
    message(FATAL_ERROR "Modified OptiScaler reference DLL is not a real build")
endif()

string(REGEX MATCH
    "constexpr auto kCanonicalOptiscalerFiles[^;]+;"
    canonical_publish_set "${runtime_source}")
string(REGEX MATCH
    "constexpr auto kDlss5OptiscalerFiles[^;]+;"
    modified_publish_set "${runtime_source}")
string(FIND "${canonical_publish_set}${modified_publish_set}"
    "OptiScaler.ini" copied_ini)
if(NOT copied_ini EQUAL -1)
    message(FATAL_ERROR "OptiScaler.ini must never be copied from either reference")
endif()

# Release-package fixtures are optional in a source workspace. The two Alpha 2
# integration references above remain mandatory and are verified independently.
if(NOT EXISTS "${SOURCE_ROOT}/runtime/XR_APILAYER_XRFrameBridge_diagnostic.dll" OR
   NOT EXISTS "${SOURCE_ROOT}/runtime/witcher3vr-optiscaler-reference" OR
   NOT EXISTS "${SOURCE_ROOT}/runtime/witcher3vr-dlss5-reference")
    message(STATUS "Alpha 2 references verified; full release-package fixtures are not staged")
    return()
endif()

file(SHA256 "${SOURCE_ROOT}/runtime/XR_APILAYER_XRFrameBridge_diagnostic.dll" ofxr_sha256)
if(NOT ofxr_sha256 STREQUAL "6b6ba7c47ef191e21e01167fc712a76f3d468d23d1cae36ea976f92fe7877698")
    message(FATAL_ERROR "V1528 requires OFXR V059")
endif()

set(dlss5_reference "${SOURCE_ROOT}/runtime/witcher3vr-dlss5-reference")
file(GLOB dlss5_entries RELATIVE "${dlss5_reference}" "${dlss5_reference}/*")
if(dlss5_entries)
    message(FATAL_ERROR "Public DLSS5 reference must be empty")
endif()

set(canonical_reference
    "${SOURCE_ROOT}/runtime/witcher3vr-optiscaler-reference")
file(GLOB canonical_entries RELATIVE "${canonical_reference}"
    "${canonical_reference}/*")
list(SORT canonical_entries)
set(expected_canonical_entries OptiScaler.dll)
list(SORT expected_canonical_entries)
if(NOT canonical_entries STREQUAL expected_canonical_entries)
    message(FATAL_ERROR "Canonical OptiScaler reference must contain only its DLL and INI")
endif()

string(REGEX MATCH
    "constexpr auto kDlss5OptiscalerFiles[^;]+;"
    modified_publish_set "${runtime_source}")
string(FIND "${modified_publish_set}" "OptiScaler/" nested_publish)
if(NOT nested_publish EQUAL -1)
    message(FATAL_ERROR "V23032 still publishes an optional OptiScaler backend")
endif()

message(STATUS "V23032 lean NGX-only payload, bindings and allowlist verified")
