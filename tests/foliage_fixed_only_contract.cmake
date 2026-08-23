if(NOT DEFINED DXGI_PROXY_SOURCE)
    message(FATAL_ERROR "DXGI_PROXY_SOURCE is required")
endif()

file(READ "${DXGI_PROXY_SOURCE}" source)

foreach(required IN ITEMS
        "build=V1410"
        "fixed=always_on runtime_ab=absent"
        "if (foliage_shader_orientation_route_active() &&"
        "lookup_foliage_orientation_pipeline(pipeline_state)"
        "bound_pipeline_state = replacement;")
    string(FIND "${source}" "${required}" found)
    if(found EQUAL -1)
        message(FATAL_ERROR "Missing fixed-only foliage contract: ${required}")
    endif()
endforeach()

foreach(forbidden IN ITEMS
        "VK_PRIOR"
        "PgUp"
        "g_foliage_orientation_fix_enabled"
        "g_foliage_orientation_pgup_down"
        "handle_foliage_orientation_ab_hotkey")
    string(FIND "${source}" "${forbidden}" found)
    if(NOT found EQUAL -1)
        message(FATAL_ERROR "Obsolete foliage A/B path remains: ${forbidden}")
    endif()
endforeach()

message(STATUS "V1410 fixed-only foliage contract verified")
