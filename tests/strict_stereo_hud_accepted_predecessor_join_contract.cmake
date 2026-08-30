if(NOT DEFINED DXGI_PROXY_SOURCE OR NOT EXISTS "${DXGI_PROXY_SOURCE}")
    message(FATAL_ERROR "dxgi_proxy.cpp was not provided")
endif()

file(READ "${DXGI_PROXY_SOURCE}" source)

foreach(required_fragment IN ITEMS
        "build=V1509 base=V1508_aer_full_vr_scene_only_admission"
        "[FIX:STRICT-STEREO-HUD-ACCEPTED-PREDECESSOR-JOIN V1494 1/7]"
        "[FIX:STRICT-STEREO-HUD-ACCEPTED-PREDECESSOR-JOIN V1494 2/7]"
        "[FIX:STRICT-STEREO-HUD-ACCEPTED-PREDECESSOR-JOIN V1494 3/7]"
        "[FIX:STRICT-STEREO-HUD-ACCEPTED-PREDECESSOR-JOIN V1494 4/7]"
        "[FIX:STRICT-STEREO-HUD-ACCEPTED-PREDECESSOR-JOIN V1494 5/7]"
        "[FIX:STRICT-STEREO-HUD-ACCEPTED-PREDECESSOR-JOIN V1494 6/7]"
        "[FIX:STRICT-STEREO-HUD-ACCEPTED-PREDECESSOR-JOIN V1494 7/7]"
        "g_mode3_strict_hud_command_list_eyes[command_list] ="
        "g_mode3_strict_hud_command_list_eyes.erase(command_list);"
        "g_mode3_strict_hud_command_list_eyes.clear();"
        "record_mode3_strict_hud_command_list_eye("
        "g_packed_accepted_pair_signal.load(std::memory_order_acquire)"
        "g_mode3_strict_hud_target_generation.load("
        "g_mode3_strict_hud_target_pair.load("
        "accepted_predecessor_pair <= current_accepted_scene_pair"
        "accepted_predecessor_tag.pair_id ="
        "candidate.pending.strict_eye_valid"
        "candidate.scene_only_draw_recorded"
        "record_mode3_scene_only_hud_output("
        "V1494 strict Stereo HUD accepted-predecessor join"
        "current_accepted_scene=validation_only"
        "no_present_parity=1"
        "dump_last_seconds(\"V1509\", 15)")
    string(FIND "${source}" "${required_fragment}" fragment_position)
    if(fragment_position EQUAL -1)
        message(FATAL_ERROR
            "Missing V1494 strict-Stereo HUD accepted-predecessor join contract: ${required_fragment}")
    endif()
endforeach()

foreach(forbidden_fragment IN ITEMS
        "STRICT-STEREO-HUD-ACCEPTED-SCENE-JOIN V1492"
        "accepted_scene_tag"
        "strict_stereo_full_vr_hud=accepted_packed_scene_pair"
        "STRICT-STEREO-HUD-PRESENT-TAG-JOIN V1491"
        "exact_present_tag")
    string(FIND "${source}" "${forbidden_fragment}" fragment_position)
    if(NOT fragment_position EQUAL -1)
        message(FATAL_ERROR
            "Superseded strict-Stereo HUD authority survived V1494: ${forbidden_fragment}")
    endif()
endforeach()

message(STATUS "V1494 strict-Stereo HUD accepted-predecessor join contract verified")

