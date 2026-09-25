if(NOT DEFINED DXGI_PROXY_SOURCE OR NOT EXISTS "${DXGI_PROXY_SOURCE}")
    message(FATAL_ERROR "dxgi_proxy.cpp was not provided")
endif()

file(READ "${DXGI_PROXY_SOURCE}" dxgi_proxy)
string(FIND "${dxgi_proxy}"
    "[FIX:CINEMA-HUD-EXACT-FRESHNESS V1552 1/1]" fix_begin)
string(FIND "${dxgi_proxy}"
    "auto* const active_hud_pipeline =" fix_end)
if(fix_begin EQUAL -1 OR fix_end EQUAL -1 OR NOT fix_begin LESS fix_end)
    message(FATAL_ERROR "Cannot isolate the Cinema draw-time HUD fallback")
endif()

math(EXPR fix_length "${fix_end} - ${fix_begin}")
string(SUBSTRING "${dxgi_proxy}" ${fix_begin} ${fix_length} fix_body)
string(FIND "${fix_body}"
    "mode3_retained_hud_pair_ready_for_active_route())" exact_ready)
if(exact_ready EQUAL -1)
    message(FATAL_ERROR
        "Cinema draw-time suppression must require the exact retained pair")
endif()

string(FIND "${fix_body}"
    "mode3_early_hud_pair_ready())" weak_ready)
if(NOT weak_ready EQUAL -1)
    message(FATAL_ERROR
        "Weak any-pair readiness still controls Cinema HUD suppression")
endif()

string(FIND "${dxgi_proxy}"
    "V1552 cinema_hud_suppression=exact_route_predecessor" startup_marker)
if(startup_marker EQUAL -1)
    message(FATAL_ERROR "Missing V1552 runtime identity marker")
endif()
