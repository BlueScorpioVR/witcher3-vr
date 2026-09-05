if(NOT DEFINED DXGI_PROXY_SOURCE OR NOT EXISTS "${DXGI_PROXY_SOURCE}")
    message(FATAL_ERROR "dxgi_proxy.cpp was not provided")
endif()

file(READ "${DXGI_PROXY_SOURCE}" source)

string(REGEX MATCHALL "g_config\\.presentation_scale" slider_reads "${source}")
list(LENGTH slider_reads slider_read_count)
if(NOT slider_read_count EQUAL 4)
    message(FATAL_ERROR
        "Presentation Size must have exactly four reads (producer, INI, config log and final route); found ${slider_read_count}")
endif()

foreach(required_fragment IN ITEMS
        "float producer_render_fov_scale()"
        "float presentation_producer_scale()"
        "bool scaled_runtime_presentation_fov("
        "scaled_fov, presentation_producer_scale(), scaled_fov"
        "ProducerProjectionScales producer_projection_scales("
        "const float presentation_scale = presentation_producer_scale();"
        "cover_scale * presentation_scale"
        "scaled_runtime_presentation_fov("
        "[TRIAL:STANDARD-PRODUCER-FOV-RESCALE V23038 1/5]"
        "[TRIAL:STANDARD-PRODUCER-FOV-RESCALE V23038 2/5]"
        "[TRIAL:STANDARD-PRODUCER-FOV-RESCALE V23038 3/5]"
        "V23038 presentation route=standard_full_image"
        "producer_coupled=1"
        "image_rect=base"
        "submitted_fov=producer"
        "presentation=producer_fov_full_image"
        "V23036 reshade_overlay=official_open_close_event"
        "V23000 ReShade secondary active")
    string(FIND "${source}" "${required_fragment}" fragment_position)
    if(fragment_position EQUAL -1)
        message(FATAL_ERROR
            "Missing ReShade/DLSS5 producer-coupled Presentation Size contract: ${required_fragment}")
    endif()
endforeach()

string(REGEX MATCHALL "scaled_runtime_presentation_fov\\(" scaled_target_calls
    "${source}")
list(LENGTH scaled_target_calls scaled_target_call_count)
if(NOT scaled_target_call_count EQUAL 3)
    message(FATAL_ERROR
        "Expected one scaled-runtime-FOV helper and two symmetric target uses; found ${scaled_target_call_count}")
endif()

foreach(forbidden_fragment IN ITEMS
        "float alternate_resize_producer_scale()"
        "apply_standard_final_presentation"
        "[FIX:FINAL-OPENXR-PRESENTATION-SIZE V1417"
        "final_presentation.image_rect"
        "final_presentation.represented_fov"
        "presentation=final_submit_only"
        "universal_final_openxr_subimage_fov_pair"
        "producer_temporal_transport=unchanged")
    string(FIND "${source}" "${forbidden_fragment}" fragment_position)
    if(NOT fragment_position EQUAL -1)
        message(FATAL_ERROR
            "Superseded final-crop Presentation Size residue remains: ${forbidden_fragment}")
    endif()
endforeach()

message(STATUS
    "V23038 ReShade/DLSS5 producer-coupled full-image Presentation Size verified")
