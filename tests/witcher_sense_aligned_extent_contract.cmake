if(NOT DEFINED DXGI_PROXY_SOURCE)
    message(FATAL_ERROR "DXGI_PROXY_SOURCE is required")
endif()

file(READ "${DXGI_PROXY_SOURCE}" source)

set(required_fragments
    "build=V1511 base=V1509_witcher_sense_aligned_extent"
    "[FIX:WITCHER-SENSE-ALIGNED-EXTENT V1511 1/2]"
    "[FIX:WITCHER-SENSE-ALIGNED-EXTENT V1511 2/2]"
    "w3vr::witcher_sense::compositor_extent_matches("
    "t0.width, t0.height, t3.width, t3.height,"
    "g_game_render_width, g_game_render_height"
    "witcher_sense_extent=paired_t0_t3"
    "requested_trim_max=31")

foreach(required_fragment IN LISTS required_fragments)
    string(FIND "${source}" "${required_fragment}" found)
    if(found EQUAL -1)
        message(FATAL_ERROR
            "Missing V1511 Witcher Senses aligned-extent contract: ${required_fragment}")
    endif()
endforeach()

set(retired_exact_extent
    "return t0.width == g_game_render_width &&\n        t0.height == g_game_render_height &&\n        t3.width == g_game_render_width &&\n        t3.height == g_game_render_height;")
string(FIND "${source}" "${retired_exact_extent}" retired_found)
if(NOT retired_found EQUAL -1)
    message(FATAL_ERROR
        "Resolution-locked Witcher Senses extent admission survived V1511")
endif()

message(STATUS "V1511 Witcher Senses aligned-extent contract verified")
