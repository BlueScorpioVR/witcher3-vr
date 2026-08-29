if(NOT DEFINED DXGI_PROXY_SOURCE OR NOT EXISTS "${DXGI_PROXY_SOURCE}")
    message(FATAL_ERROR "dxgi_proxy.cpp was not provided")
endif()

file(READ "${DXGI_PROXY_SOURCE}" source)

foreach(required_fragment IN ITEMS
        "build=V1442 base=V1441_noaa_aggressive_optimization"
        "[FIX:FULL-VR-FALLBACK-RAW-FOV V1424]"
        "xr_fov = &g_xr_views[static_cast<size_t>(eye)].fov;"
        "recursive_shared_fov_input=removed"
        "[FIX:OPENING-CUTSCENE-ASYM-FALLBACK-FOV V1418 1/2]"
        "[FIX:OPENING-CUTSCENE-ASYM-FALLBACK-FOV V1418 2/2]"
        "bool publish_shared_mode3_projection_fov("
        "if (symmetric_asymmetric_full_vr_fallback &&"
        "!native_asymmetric_full_vr_projection_applied &&"
        "shared_asymmetric_fallback_fov_ready)"
        "shared_asymmetric_fallback_fov_published ="
        "shared_asymmetric_fallback_horizontal_span,"
        "shared_asymmetric_fallback_vertical_fov);"
        "shared_fov_published=%d"
        "V1418 opening_cutscene_asym_fallback_fov=published_after_corrected_camera_write mono=unchanged native_asymmetric_factory=unchanged"
        "if (symmetric_subimage_requested &&"
        "!mode3_symmetric_subimage) {")
    string(FIND "${source}" "${required_fragment}" fragment_position)
    if(fragment_position EQUAL -1)
        message(FATAL_ERROR
            "Missing V1418 opening-cutscene ASYM fallback FOV contract: ${required_fragment}")
    endif()
endforeach()

string(REGEX MATCHALL
    "publish_shared_mode3_projection_fov\\(" publisher_references "${source}")
list(LENGTH publisher_references publisher_reference_count)
if(NOT publisher_reference_count EQUAL 3)
    message(FATAL_ERROR
        "Shared Mode-3 FOV must have one owner and exactly two producers; found ${publisher_reference_count} references")
endif()

foreach(component IN ITEMS left right up down)
    string(REGEX MATCHALL
        "g_hmd_render_fov_${component}\\.store\\(" component_stores "${source}")
    list(LENGTH component_stores component_store_count)
    if(NOT component_store_count EQUAL 1)
        message(FATAL_ERROR
            "Shared FOV ${component} must be written only by the common publisher; found ${component_store_count} stores")
    endif()
endforeach()

string(REGEX MATCHALL
    "g_hmd_render_fov_valid\\.store\\(true\\)" valid_stores "${source}")
list(LENGTH valid_stores valid_store_count)
if(NOT valid_store_count EQUAL 1)
    message(FATAL_ERROR
        "Shared FOV validity must be published only by the common owner; found ${valid_store_count} stores")
endif()

string(FIND "${source}"
    "[FIX:FULL-VR-FINAL-FRAME-CAMERA 1/3]" fallback_begin)
string(FIND "${source}"
    "[FIX:FULL-VR-FINAL-FRAME-CAMERA 2/3]" fallback_end)
if(fallback_begin EQUAL -1 OR fallback_end EQUAL -1 OR
        fallback_end LESS_EQUAL fallback_begin)
    message(FATAL_ERROR "Could not isolate the Full-VR frame-camera fallback")
endif()
math(EXPR fallback_length "${fallback_end} - ${fallback_begin}")
string(SUBSTRING "${source}" ${fallback_begin} ${fallback_length}
    fallback_source)
string(FIND "${fallback_source}"
    "if (!safe_write_engine_view_snapshot(" corrected_camera_write)
string(FIND "${fallback_source}"
    "[FIX:FULL-VR-FALLBACK-RAW-FOV V1424]" raw_fov_selection)
string(FIND "${fallback_source}"
    "[FIX:OPENING-CUTSCENE-ASYM-FALLBACK-FOV V1418 2/2]"
    fallback_publication)
if(raw_fov_selection EQUAL -1 OR corrected_camera_write EQUAL -1 OR
        fallback_publication EQUAL -1 OR
        corrected_camera_write LESS_EQUAL raw_fov_selection OR
        fallback_publication LESS_EQUAL corrected_camera_write)
    message(FATAL_ERROR
        "Raw runtime FOV must drive the corrected camera before publication")
endif()

message(STATUS "V1418 opening-cutscene ASYM fallback FOV contract verified")
