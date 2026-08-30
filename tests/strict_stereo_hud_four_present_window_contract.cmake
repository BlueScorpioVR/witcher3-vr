if(NOT DEFINED DXGI_PROXY_SOURCE OR NOT EXISTS "${DXGI_PROXY_SOURCE}")
    message(FATAL_ERROR "dxgi_proxy.cpp was not provided")
endif()

file(READ "${DXGI_PROXY_SOURCE}" source)

foreach(required_fragment IN ITEMS
        "build=V1501 base=V1499_witcher_sense_expanded_partition_cache"
        "[FIX:STRICT-STEREO-HUD-FOUR-PRESENT-WINDOW V1493 1/5]"
        "[FIX:STRICT-STEREO-HUD-FOUR-PRESENT-WINDOW V1493 2/5]"
        "[FIX:STRICT-STEREO-HUD-FOUR-PRESENT-WINDOW V1493 3/5]"
        "[FIX:STRICT-STEREO-HUD-FOUR-PRESENT-WINDOW V1493 4/5]"
        "kMode3StrictHudJoinMaxPresentDistance = 4"
        "strict_stereo_hud_join_window_matches("
        "distance <= kMode3StrictHudJoinMaxPresentDistance"
        "strict_stereo_hud_join_max_present_distance=4"
        "aer_window=unchanged_2"
        "dump_last_seconds(\"V1501\", 15)")
    string(FIND "${source}" "${required_fragment}" fragment_position)
    if(fragment_position EQUAL -1)
        message(FATAL_ERROR
            "Missing V1493 strict-Stereo HUD four-Present window contract: ${required_fragment}")
    endif()
endforeach()

message(STATUS "V1493 strict-Stereo HUD four-Present window contract verified")
