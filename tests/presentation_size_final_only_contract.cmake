if(NOT DEFINED DXGI_PROXY_SOURCE OR NOT EXISTS "${DXGI_PROXY_SOURCE}")
    message(FATAL_ERROR "dxgi_proxy.cpp was not provided")
endif()

file(READ "${DXGI_PROXY_SOURCE}" source)

set(final_hook "const float final_presentation_scale = std::clamp(")
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
        "[FIX:FINAL-OPENXR-PRESENTATION-SIZE V1417 1/2]"
        "[FIX:FINAL-OPENXR-PRESENTATION-SIZE V1417 2/2]"
        "if (final_presentation_scale < 1.0f)"
        "const XrRect2Di base_presentation_rect ="
        "const XrFovf base_presentation_fov ="
        "final_presentation_scale,"
        "derive_symmetric_eye_subimage("
        "projection_views[eye].subImage.imageRect ="
        "final_presentation.image_rect;"
        "projection_views[eye].fov ="
        "final_presentation.represented_fov;"
        "V1417 presentation_size=universal_final_openxr_subimage_fov_pair")
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
        "const uint32_t presentation_height"
        "requested_scale"
        "fullscreen_cover_fraction"
        "legacy_presentation_scale"
        "submitted_crop_fraction"
        "scaled_fov_projection"
        "scaled_fov_direct_copy"
        "final_presentation_fov"
        "image_rect=slider_independent"
        "universal_final_openxr_fov_only"
        "PRESENTATION-SCALE-FOV"
        "PRESENTATION-COVER-SCALE")
    string(FIND "${source}" "${forbidden_fragment}" fragment_position)
    if(NOT fragment_position EQUAL -1)
        message(FATAL_ERROR
            "Upstream Presentation Size residue remains: ${forbidden_fragment}")
    endif()
endforeach()

string(FIND "${source}"
    "[FIX:FINAL-OPENXR-PRESENTATION-SIZE V1417 2/2]"
    final_application_position)
string(FIND "${source}"
    "projection_views[eye].subImage.imageRect = projection_image_rect;"
    final_image_rect_position)
if(final_application_position LESS final_image_rect_position)
    message(FATAL_ERROR
        "Presentation Size must be applied after the final route imageRect")
endif()

message(STATUS "V1417 universal final subimage/FOV Presentation Size contract verified")
