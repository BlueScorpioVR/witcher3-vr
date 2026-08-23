if(NOT DEFINED DXGI_PROXY_SOURCE OR NOT EXISTS "${DXGI_PROXY_SOURCE}")
    message(FATAL_ERROR "dxgi_proxy.cpp was not provided")
endif()

file(READ "${DXGI_PROXY_SOURCE}" source)

set(final_hook "const float requested_scale = std::clamp(")
string(FIND "${source}" "${final_hook}" final_hook_position)
if(final_hook_position EQUAL -1)
    message(FATAL_ERROR "Final OpenXR Presentation Size hook is missing")
endif()

string(REGEX MATCHALL "g_config\\.presentation_scale" slider_reads "${source}")
list(LENGTH slider_reads slider_read_count)
if(NOT slider_read_count EQUAL 3)
    message(FATAL_ERROR
        "Presentation Size must have exactly three reads (INI, config log, final OpenXR); found ${slider_read_count}")
endif()

string(SUBSTRING "${source}" 0 ${final_hook_position} upstream_source)
string(REGEX MATCHALL "g_config\\.presentation_scale" upstream_slider_reads
    "${upstream_source}")
list(LENGTH upstream_slider_reads upstream_slider_read_count)
if(NOT upstream_slider_read_count EQUAL 2)
    message(FATAL_ERROR
        "Presentation Size escaped into producer code before final OpenXR; expected only INI and config-log reads, found ${upstream_slider_read_count}")
endif()

foreach(required_fragment IN ITEMS
        "float producer_render_fov_scale()"
        "ProducerProjectionScales producer_projection_scales("
        "producer_fovs[eye] = g_xr_views[eye].fov;"
        "presentation=final_submit_only"
        "V1391 presentation_size=final_openxr_only")
    string(FIND "${source}" "${required_fragment}" fragment_position)
    if(fragment_position EQUAL -1)
        message(FATAL_ERROR
            "Missing final-only Presentation Size contract: ${required_fragment}")
    endif()
endforeach()

foreach(forbidden_fragment IN ITEMS
        "presentation_render_fov_scale"
        "presentation_projection_scales"
        "g_config.presentation_scale / cover_fraction"
        "presentation_fovs[eye]"
        "const uint32_t presentation_width"
        "const uint32_t presentation_height")
    string(FIND "${source}" "${forbidden_fragment}" fragment_position)
    if(NOT fragment_position EQUAL -1)
        message(FATAL_ERROR
            "Upstream Presentation Size residue remains: ${forbidden_fragment}")
    endif()
endforeach()

message(STATUS "V1391 final-only Presentation Size contract verified")
