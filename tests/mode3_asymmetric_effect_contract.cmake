if(NOT DEFINED DXGI_PROXY_SOURCE OR NOT EXISTS "${DXGI_PROXY_SOURCE}")
    message(FATAL_ERROR "DXGI proxy source is required")
endif()

file(READ "${DXGI_PROXY_SOURCE}" source)

foreach(required_marker IN ITEMS
        "native_asymmetric_effect_preparation_configured("
        "transparent_effect_draw_route_active()"
        "decide_effect_draw_projection("
        "store_effect_draw_producer_authority("
        "effect_producer_projection"
        "effect_producer_transaction"
        "real_smoke_center_fix_route_configured()"
        "resolve_focus_fire_horizontal_draw_pso("
        "select_real_smoke_offaxis_pipeline(")
    string(FIND "${source}" "${required_marker}" marker_index)
    if(marker_index EQUAL -1)
        message(FATAL_ERROR
            "Missing asymmetric-effect contract marker: ${required_marker}")
    endif()
endforeach()

string(FIND "${source}"
    "void __fastcall hook_engine_dlss_command(" command_hook_index)
string(FIND "${source}"
    "Publish the producer-owned" producer_store_index)
string(FIND "${source}"
    "g_engine_dlss_command(context, stream);" command_dispatch_index)
if(command_hook_index EQUAL -1 OR producer_store_index EQUAL -1 OR
        command_dispatch_index EQUAL -1 OR
        producer_store_index LESS command_hook_index OR
        producer_store_index GREATER command_dispatch_index)
    message(FATAL_ERROR
        "DLSS producer authority must be stamped before command recording")
endif()

foreach(obsolete_marker IN ITEMS
        "strict_stereo_asymmetric_effect_preparation_configured"
        "strict_stereo_asymmetric_effect_application_active"
        "automatic_focus_projection_route_active"
        "native_asymmetric_transparent_center_route_active"
        "final_native_temporal_aer")
    string(FIND "${source}" "${obsolete_marker}" obsolete_index)
    if(NOT obsolete_index EQUAL -1)
        message(FATAL_ERROR
            "Obsolete route-wide effect exclusion remains: ${obsolete_marker}")
    endif()
endforeach()
