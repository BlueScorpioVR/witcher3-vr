if(NOT DEFINED DXGI_PROXY_SOURCE OR NOT EXISTS "${DXGI_PROXY_SOURCE}")
    message(FATAL_ERROR "dxgi_proxy.cpp was not provided")
endif()

file(READ "${DXGI_PROXY_SOURCE}" source)

foreach(required_fragment IN ITEMS
        "build=V1511 base=V1509_witcher_sense_aligned_extent"
        "[FIX:AER-FULL-VR-RETAINED-HUD V1508 1/6]"
        "[FIX:AER-FULL-VR-RETAINED-HUD V1508 2/6]"
        "[FIX:AER-FULL-VR-RETAINED-HUD V1508 3/6]"
        "[FIX:AER-FULL-VR-RETAINED-HUD V1508 4/6]"
        "[FIX:AER-FULL-VR-RETAINED-HUD V1508 5/6]"
        "[FIX:AER-FULL-VR-RETAINED-HUD V1508 6/6]"
        "bool mode3_aer_sequential_retained_hud_configured()"
        "bool mode3_aer_sequential_full_vr_retained_hud_active()"
        "mode3_aer_sequential_full_vr_retained_hud_active();"
        "bool mode3_aer_submitted_hud_join_active()"
        "mode3_aer_sequential_retained_hud_configured(),"
        "void record_mode3_aer_retained_hud_tag("
        "? resolve_aer_cinema_command_list_tag(command_list, tag)"
        "mode3_aer_submitted_hud_join_active() ||"
        "if (mode3_aer_submitted_hud_join_active() &&"
        "aer_full_vr_exact_command_list"
        "V1508 aer_full_vr_hud=stereo_retained_single_owner"
        "dump_last_seconds(\"V1511\", 15)")
    string(FIND "${source}" "${required_fragment}" fragment_position)
    if(fragment_position EQUAL -1)
        message(FATAL_ERROR
            "Missing V1508 AER Full-VR retained-HUD contract: ${required_fragment}")
    endif()
endforeach()

foreach(forbidden_fragment IN ITEMS
        "record_mode3_aer_afw_final_hud_tag("
        "kForceMode3AerAfwSubmittedHudJoinBuild"
        "kForceMode3AerSubmittedHudJoinBuild"
        "peek_mode3_aer_afw_final_hud_tag("
        "consume_mode3_aer_afw_final_hud_tag("
        "taau_exact_command_list"
        "taau_exact_tag_missing")
    string(FIND "${source}" "${forbidden_fragment}" fragment_position)
    if(NOT fragment_position EQUAL -1)
        message(FATAL_ERROR
            "Superseded backend-specific AER HUD path survived: ${forbidden_fragment}")
    endif()
endforeach()

message(STATUS "V1508 AER Full-VR retained-HUD contract verified")
