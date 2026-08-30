if(NOT DEFINED DXGI_PROXY_SOURCE OR NOT EXISTS "${DXGI_PROXY_SOURCE}")
    message(FATAL_ERROR "dxgi_proxy.cpp was not provided")
endif()

file(READ "${DXGI_PROXY_SOURCE}" source)

foreach(required_fragment IN ITEMS
        "build=V1511 base=V1509_witcher_sense_aligned_extent"
        "[FIX:STRICT-STEREO-GAMEPLAY-RETAINED-HUD V1495 1/3]"
        "[FIX:STRICT-STEREO-GAMEPLAY-RETAINED-HUD V1495 2/3]"
        "[FIX:STRICT-STEREO-GAMEPLAY-RETAINED-HUD V1495 3/3]"
        "!mode3_aer_afw_baked_hud_cinema_active()) ||"
        "mode3_aer_afw_post_hud_gameplay_active();"
        "V1495 strict_stereo_gameplay_hud=retained_after_bootstrap"
        "accepted_predecessor_join=V1494"
        "dump_last_seconds(\"V1511\", 15)")
    string(FIND "${source}" "${required_fragment}" fragment_position)
    if(fragment_position EQUAL -1)
        message(FATAL_ERROR
            "Missing V1495 strict-Stereo gameplay retained-HUD contract: ${required_fragment}")
    endif()
endforeach()

foreach(forbidden_fragment IN ITEMS
        "strict_stereo_retained_hud_scene_active"
        "[FIX:STRICT-STEREO-GAMEPLAY-BAKED-HUD V1483"
        "V1483 strict_stereo_gameplay_hud=native_baked_single_owner")
    string(FIND "${source}" "${forbidden_fragment}" fragment_position)
    if(NOT fragment_position EQUAL -1)
        message(FATAL_ERROR
            "Superseded V1483 gameplay HUD path survived V1495: ${forbidden_fragment}")
    endif()
endforeach()

message(STATUS "V1495 strict-Stereo gameplay retained-HUD contract verified")
