if(NOT DEFINED DXGI_PROXY_SOURCE)
    message(FATAL_ERROR "DXGI_PROXY_SOURCE is required")
endif()

file(READ "${DXGI_PROXY_SOURCE}" source)

set(required_fragments
    "[FIX:WITCHER-SENSE-DESCRIPTOR-EXTENT-AUTHORITY V1526 1/2]"
    "[FIX:WITCHER-SENSE-DESCRIPTOR-EXTENT-AUTHORITY V1526 2/2]"
    "w3vr::witcher_sense::compositor_extent_matches("
    "t0.width, t0.height, t3.width, t3.height);"
    "witcher_sense_extent=paired_descriptor_authority"
    "live_requested_extent=diagnostic_only"
    "alt_resize_early_publication=isolated"
    "pso_draw_root_formats_descriptors=V1501_unchanged")

foreach(required_fragment IN LISTS required_fragments)
    string(FIND "${source}" "${required_fragment}" found)
    if(found EQUAL -1)
        message(FATAL_ERROR
            "Missing V1526 Witcher Senses descriptor-extent authority: ${required_fragment}")
    endif()
endforeach()

set(forbidden_fragments
    "[FIX:WITCHER-SENSE-ALIGNED-EXTENT V1511"
    "requested_trim_max=31"
    "t0.width, t0.height, t3.width, t3.height,\n        g_game_render_width, g_game_render_height")

foreach(forbidden_fragment IN LISTS forbidden_fragments)
    string(FIND "${source}" "${forbidden_fragment}" found)
    if(NOT found EQUAL -1)
        message(FATAL_ERROR
            "Superseded Witcher Senses extent authority remains: ${forbidden_fragment}")
    endif()
endforeach()

message(STATUS "V1526 Witcher Senses descriptor-pair extent authority verified")
