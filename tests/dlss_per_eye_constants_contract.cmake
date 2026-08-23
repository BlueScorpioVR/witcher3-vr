if(NOT DEFINED DXGI_PROXY_SOURCE)
    message(FATAL_ERROR "DXGI_PROXY_SOURCE is required")
endif()

file(READ "${DXGI_PROXY_SOURCE}" source)

foreach(required
    "void install_engine_view_constants_hook()"
    "!dlss_sequential_mode_active())"
    "reinterpret_cast<uint32_t*>(dlss_state + 0x6C)"
    "decide_builder_reentry("
    "true, mode3_aer_presentation_active()"
    "*constants_builder_frame = frame_id - 1"
    "g_engine_view_constants("
    "dlss_state, frame_data"
    "publish_sequential_dlss_constants_receipt("
    "route_flight::set_enabled(true)"
    "dump_last_seconds(\"V1368\", 15)")
    string(FIND "${source}" "${required}" found)
    if(found EQUAL -1)
        message(FATAL_ERROR "Missing V1364 DLSS constants contract: ${required}")
    endif()
endforeach()

foreach(forbidden
    "g_dlss_scene_reset"
    "kDlssSceneResetWindowPairs"
    "arm_mode3_dlss_scene_reset")
    string(FIND "${source}" "${forbidden}" found)
    if(NOT found EQUAL -1)
        message(FATAL_ERROR "Rejected V1340 residue remains: ${forbidden}")
    endif()
endforeach()
