if(NOT DEFINED RENDERER_SOURCE)
    message(FATAL_ERROR "RENDERER_SOURCE is required")
endif()

file(READ "${RENDERER_SOURCE}" source)

foreach(required_text IN ITEMS
    "float world_detail_range{1.0f};"
    "read_ini_float(\"openxr\", \"world_detail_range\", 1.0f)"
    "clamp_world_detail_range("
    "select_target_distance_scale("
    "select_target_raw_distance_scale("
    "destination[kRawDistanceScaleIndex] = target_raw_scale;"
    "destination[kDistanceScaleIndex] = target_scale;"
    "native_scale < original_scale * 0.8f")
    string(FIND "${source}" "${required_text}" found)
    if(found EQUAL -1)
        message(FATAL_ERROR
            "V1516 world-detail range integration is missing: ${required_text}")
    endif()
endforeach()

foreach(forbidden_text IN ITEMS
    "destination[kVisibleFovIndex] ="
    "source[kVisibleFovIndex] =")
    string(FIND "${source}" "${forbidden_text}" found)
    if(NOT found EQUAL -1)
        message(FATAL_ERROR
            "V1516 must not rewrite visible projection FOV: ${forbidden_text}")
    endif()
endforeach()
