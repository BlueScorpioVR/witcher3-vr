if(NOT DEFINED DXGI_PROXY_SOURCE OR NOT EXISTS "${DXGI_PROXY_SOURCE}")
    message(FATAL_ERROR "DXGI proxy source is required")
endif()

file(READ "${DXGI_PROXY_SOURCE}" source)

foreach(required_marker IN ITEMS
        "native_asymmetric_effect_preparation_configured("
        "native_asymmetric_effect_center_application_active("
        "real_smoke_center_fix_route_configured()"
        "resolve_focus_fire_horizontal_draw_pso("
        "select_real_smoke_offaxis_pipeline(")
    string(FIND "${source}" "${required_marker}" marker_index)
    if(marker_index EQUAL -1)
        message(FATAL_ERROR
            "Missing asymmetric-effect contract marker: ${required_marker}")
    endif()
endforeach()

string(REGEX MATCHALL
    "native_asymmetric_effect_center_application_active\\("
    application_sites "${source}")
list(LENGTH application_sites application_site_count)
if(application_site_count LESS 2)
    message(FATAL_ERROR
        "Automatic effects and specialized smoke must share the ASYM gate")
endif()

foreach(obsolete_marker IN ITEMS
        "strict_stereo_asymmetric_effect_preparation_configured"
        "strict_stereo_asymmetric_effect_application_active"
        "automatic_focus_projection_route_active"
        "final_native_temporal_aer")
    string(FIND "${source}" "${obsolete_marker}" obsolete_index)
    if(NOT obsolete_index EQUAL -1)
        message(FATAL_ERROR
            "Obsolete route-wide effect exclusion remains: ${obsolete_marker}")
    endif()
endforeach()
