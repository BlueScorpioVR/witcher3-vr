if(NOT DEFINED DXGI_PROXY_SOURCE OR NOT EXISTS "${DXGI_PROXY_SOURCE}")
    message(FATAL_ERROR "DXGI proxy source is required")
endif()

file(READ "${DXGI_PROXY_SOURCE}" source)

foreach(required_fragment IN ITEMS
        "build=V1511 base=V1509_witcher_sense_aligned_extent"
        "[FIX:STRICT-STEREO-GAMEPLAY-HUD-EYE-AUTHORITY V1496 1/3]"
        "[FIX:STRICT-STEREO-GAMEPLAY-HUD-EYE-AUTHORITY V1496 2/3]"
        "[FIX:STRICT-STEREO-GAMEPLAY-HUD-EYE-AUTHORITY V1496 3/3]"
        "record_mode3_strict_hud_command_list_eye(\n                command_list, hud_eye);"
        "strict_stereo_gameplay_hud_eye=exact_pso_selected"
        "diagnostic_logging_required=0"
        "dump_last_seconds(\"V1511\", 15)")
    string(FIND "${source}" "${required_fragment}" fragment_position)
    if(fragment_position EQUAL -1)
        message(FATAL_ERROR
            "Missing V1496 strict-Stereo gameplay eye-authority contract: ${required_fragment}")
    endif()
endforeach()

set(retired_scope
    "if (automatic_full_vr_hud) {\n                record_mode3_strict_hud_command_list_eye(")
string(FIND "${source}" "${retired_scope}" retired_scope_position)
if(NOT retired_scope_position EQUAL -1)
    message(FATAL_ERROR
        "V1494 Full-VR-only strict HUD eye scope survived V1496")
endif()

message(STATUS "V1496 strict-Stereo gameplay eye-authority contract verified")
