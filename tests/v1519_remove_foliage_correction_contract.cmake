if(NOT DEFINED SOURCE_ROOT OR NOT IS_DIRECTORY "${SOURCE_ROOT}")
    message(FATAL_ERROR "V1519 source root was not provided")
endif()

set(dxgi_proxy "${SOURCE_ROOT}/src/dxgi_proxy.cpp")
set(cmake_source "${SOURCE_ROOT}/CMakeLists.txt")
if(NOT EXISTS "${dxgi_proxy}" OR NOT EXISTS "${cmake_source}")
    message(FATAL_ERROR "V1519 renderer sources are missing")
endif()

file(READ "${dxgi_proxy}" source)
file(READ "${cmake_source}" cmake)

set(forbidden_source_fragments
    "foliage_hmd_base"
    "foliage_bound_basis"
    "FoliageBoundBasis"
    "g_foliage_bound_basis"
    "V1419 foliage"
    "PERF:NOAA-FOLIAGE-CHUNKS")
foreach(fragment IN LISTS forbidden_source_fragments)
    string(FIND "${source}" "${fragment}" position)
    if(NOT position EQUAL -1)
        message(FATAL_ERROR
            "Superseded foliage correction remains in renderer: ${fragment}")
    endif()
endforeach()

set(retired_paths
    "${SOURCE_ROOT}/src/foliage_hmd_base_policy.h"
    "${SOURCE_ROOT}/tests/foliage_hmd_base_policy_tests.cpp"
    "${SOURCE_ROOT}/tests/foliage_native_current_previous_descriptor_contract.cmake"
    "${SOURCE_ROOT}/support/foliage_native_table_lifetime_contract.json")
foreach(path IN LISTS retired_paths)
    if(EXISTS "${path}")
        message(FATAL_ERROR "Retired foliage correction artifact remains: ${path}")
    endif()
endforeach()

set(forbidden_cmake_fragments
    "w3vr_foliage_hmd_base_policy_tests"
    "renderer_foliage_hmd_base_policy"
    "renderer_foliage_native_current_previous_descriptor_contract")
foreach(fragment IN LISTS forbidden_cmake_fragments)
    string(FIND "${cmake}" "${fragment}" position)
    if(NOT position EQUAL -1)
        message(FATAL_ERROR "Retired foliage test remains in CMake: ${fragment}")
    endif()
endforeach()

message(STATUS "V1519 foliage correction removal contract verified")
