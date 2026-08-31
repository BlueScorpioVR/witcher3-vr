foreach(required_variable IN ITEMS
    LAUNCHER_MAIN_SOURCE LAUNCHER_CONFIG_SOURCE LAUNCHER_CONFIG_HEADER
    LAUNCHER_DEFAULT_INI)
    if(NOT DEFINED ${required_variable})
        message(FATAL_ERROR "${required_variable} is required")
    endif()
endforeach()

file(READ "${LAUNCHER_MAIN_SOURCE}" main_source)
file(READ "${LAUNCHER_CONFIG_SOURCE}" config_source)
file(READ "${LAUNCHER_CONFIG_HEADER}" config_header)
file(READ "${LAUNCHER_DEFAULT_INI}" default_ini)

foreach(fragment IN ITEMS
    "IdWorldDetailRange"
    "IdWorldDetailRangeValue"
    "AddTrack(193, 234, 310, IdWorldDetailRange, 40, 100)"
    "state.world_detail_range = static_cast<float>(SendMessageW("
    "loaded.state.world_detail_range * 100.0f"
    "defaults.world_detail_range * 100.0f")
    string(FIND "${main_source}" "${fragment}" found)
    if(found EQUAL -1)
        message(FATAL_ERROR "V1518 launcher UI fragment missing: ${fragment}")
    endif()
endforeach()

foreach(fragment IN ITEMS
    "float world_detail_range{1.0f};")
    string(FIND "${config_header}" "${fragment}" found)
    if(found EQUAL -1)
        message(FATAL_ERROR "V1518 launcher state fragment missing: ${fragment}")
    endif()
endforeach()

foreach(fragment IN ITEMS
    "constexpr int kCurrentConfigVersion = 18;"
    "ReadFloat(*vr, \"openxr\", \"world_detail_range\", 1.0f)"
    "vr_ini.Set(\"openxr\", \"world_detail_range\", FloatString("
    "std::clamp(state.world_detail_range, 0.4f, 1.0f)")
    string(FIND "${config_source}" "${fragment}" found)
    if(found EQUAL -1)
        message(FATAL_ERROR "V1518 launcher persistence missing: ${fragment}")
    endif()
endforeach()

foreach(fragment IN ITEMS
    "config_version=18"
    "world_detail_range=1.000")
    string(FIND "${default_ini}" "${fragment}" found)
    if(found EQUAL -1)
        message(FATAL_ERROR "V1518 launcher default missing: ${fragment}")
    endif()
endforeach()
