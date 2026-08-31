foreach(required_variable IN ITEMS
        DXGI_PROXY_SOURCE
        OPENXR_GEOMETRY_SOURCE
        LAUNCHER_MAIN
        LAUNCHER_CONFIG
        LAUNCHER_HEADER
        LAUNCHER_DEFAULTS)
    if(NOT DEFINED ${required_variable} OR
            NOT EXISTS "${${required_variable}}")
        message(FATAL_ERROR "${required_variable} was not provided")
    endif()
endforeach()

file(READ "${DXGI_PROXY_SOURCE}" renderer)
file(READ "${OPENXR_GEOMETRY_SOURCE}" geometry)
file(READ "${LAUNCHER_MAIN}" launcher_main)
file(READ "${LAUNCHER_CONFIG}" launcher_config)
file(READ "${LAUNCHER_HEADER}" launcher_header)
file(READ "${LAUNCHER_DEFAULTS}" launcher_defaults)

foreach(required IN ITEMS
        "bool presentation_black_resize{};"
        "presentation_black_resize = read_ini_bool("
        "XR_SWAPCHAIN_USAGE_TRANSFER_SRC_BIT"
        "initialize_presentation_window_pipeline("
        "render_presentation_black_resize("
        "[TRIAL:ALT-RESIZE-PRODUCER-COUPLING V1525 1/4]"
        "[TRIAL:ALT-RESIZE-PRODUCER-COUPLING V1525 2/4]"
        "[TRIAL:ALT-RESIZE-PRODUCER-COUPLING V1525 3/4]"
        "[TRIAL:ALT-RESIZE-PRODUCER-COUPLING V1525 4/4]"
        "float alternate_resize_producer_scale()"
        "cover_scale * alternate_scale"
        "scale_asymmetric_projection_fov("
        "const XrFovf runtime_submission_fov ="
        "!presentation_black_resize_requested"
        "projection_views[eye].fov ="
        "black_resize_presentations[eye].submitted_fov"
        "producer_coupled=1"
        "submitted_fov=runtime"
        "image_rect=base")
    string(FIND "${renderer}" "${required}" found)
    if(found EQUAL -1)
        message(FATAL_ERROR
            "Missing V1525 renderer black-resize contract: ${required}")
    endif()
endforeach()

foreach(required IN ITEMS
        "derive_black_resize_presentation("
        "presentation.submitted_fov = base_fov;"
        "optical_x + presentation_scale *"
        "optical_y + presentation_scale *")
    string(FIND "${geometry}" "${required}" found)
    if(found EQUAL -1)
        message(FATAL_ERROR
            "Missing V1525 runtime-FOV geometry: ${required}")
    endif()
endforeach()

foreach(forbidden IN ITEMS
        "1.0f / presentation_scale"
        "tangent_fov_scale=reciprocal")
    string(FIND "${geometry}${renderer}" "${forbidden}" found)
    if(NOT found EQUAL -1)
        message(FATAL_ERROR
            "Superseded V1522 reciprocal-FOV path remains: ${forbidden}")
    endif()
endforeach()

foreach(required IN ITEMS
        "IdPresentationBlackResize"
        "L\"Alt. resize\""
        "Required for Presentation Size to work correctly with SteamVR"
        "Image quality is slightly reduced"
        "Leave it off if Presentation Size already works with your OpenXR runtime")
    string(FIND "${launcher_main}" "${required}" found)
    if(found EQUAL -1)
        message(FATAL_ERROR
            "Missing V1522 launcher control: ${required}")
    endif()
endforeach()

foreach(required IN ITEMS
        "bool presentation_black_resize{};"
        "constexpr int kCurrentConfigVersion = 18;"
        "MigrateConfigurationToV18"
        "ini.Set(\"openxr\", \"presentation_black_resize\", \"0\")"
        "result.state.presentation_black_resize = ReadBool("
        "state.presentation_black_resize ? \"1\" : \"0\"")
    string(FIND "${launcher_header}${launcher_config}" "${required}" found)
    if(found EQUAL -1)
        message(FATAL_ERROR
            "Missing V1522 launcher persistence: ${required}")
    endif()
endforeach()

string(FIND "${launcher_defaults}"
    "presentation_black_resize=0" default_found)
if(default_found EQUAL -1)
    message(FATAL_ERROR "V1522 SteamVR presenter does not default off")
endif()

string(FIND "${renderer}"
    "composite_mode3_hud_into_projection_image(" hud_position)
string(FIND "${renderer}"
    "if (command_list_recording && submitted &&\n            presentation_black_resize_active)"
    resize_position)
if(hud_position EQUAL -1 OR resize_position EQUAL -1 OR
        resize_position LESS hud_position)
    message(FATAL_ERROR
        "V1522 black-resize must run after retained-HUD composition")
endif()

message(STATUS
    "V1525 optional black-canvas producer-coupled presenter verified")
