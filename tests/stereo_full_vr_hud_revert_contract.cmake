if(NOT DEFINED DXGI_PROXY_SOURCE OR NOT EXISTS "${DXGI_PROXY_SOURCE}")
    message(FATAL_ERROR "DXGI proxy source is required")
endif()

file(READ "${DXGI_PROXY_SOURCE}" source)

foreach(required_fragment IN ITEMS
        "build=V1511 base=V1509_witcher_sense_aligned_extent"
        "V1479 stereo_full_vr_hud=V1476_strict_predecessor_freshness"
        "bool mode3_retained_hud_pair_ready_for_active_route("
        "if (!mode3_strict_stereo_submitted_hud_join_active()) {"
        "return mode3_early_hud_pair_ready();"
        "const uint64_t target_pair = preparing_scene_draw"
        "preparing_scene_draw ? target_pair : 0"
        "get_mode3_early_hud_pair("
        "selected_pair == target_pair"
        "g_mode3_strict_hud_target_generation.load("
        "g_mode3_strict_hud_target_pair.load(")
    string(FIND "${source}" "${required_fragment}" fragment_index)
    if(fragment_index EQUAL -1)
        message(FATAL_ERROR
            "Missing V1479 restored HUD freshness contract: ${required_fragment}")
    endif()
endforeach()

foreach(retired_fragment IN ITEMS
        "STEREO-DLSS-FULL-VR-AER-HUD V1477"
        "stereo_dlss_full_vr_aer_hud"
        "V1477 stereo_dlss_full_vr_hud=aer_retained_scene_only_then_late")
    string(FIND "${source}" "${retired_fragment}" retired_index)
    if(NOT retired_index EQUAL -1)
        message(FATAL_ERROR
            "Superseded V1477 HUD path survived in V1479: ${retired_fragment}")
    endif()
endforeach()

string(FIND "${source}"
    "strict_stereo_retained_hud_pair_fresh(\n            generation"
    retired_moving_head_gate)
if(NOT retired_moving_head_gate EQUAL -1)
    message(FATAL_ERROR
        "The moving accepted-head freshness gate survived V1556")
endif()

message(STATUS "V1556 exact retained-HUD source readiness verified")
