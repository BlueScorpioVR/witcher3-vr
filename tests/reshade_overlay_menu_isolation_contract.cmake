# [FIX:RESHADE-OVERLAY-MENU-ISOLATION V23036 4/4] Keep the integration tied
# to ReShade's official transition event. A keyboard-specific workaround would
# regress remapped overlays and is intentionally forbidden here.
file(READ "${DXGI_PROXY_SOURCE}" source)

foreach(required
    "V23036 reshade_overlay=official_open_close_event"
    "ReShadeRegisterAddon"
    "ReShadeRegisterEventForAddon"
    "kReShadeOpenOverlayEvent = 86"
    "on_reshade_open_overlay"
    "g_engine_raw_menu_state"
    "effective_engine_menu_state(")
    string(FIND "${source}" "${required}" found)
    if(found EQUAL -1)
        message(FATAL_ERROR "Missing V23036 ReShade overlay isolation contract: ${required}")
    endif()
endforeach()

foreach(forbidden
    "GetAsyncKeyState(VK_F4)"
    "GetKeyState(VK_F4)")
    string(FIND "${source}" "${forbidden}" found)
    if(NOT found EQUAL -1)
        message(FATAL_ERROR "V23036 must not infer overlay state from F4: ${forbidden}")
    endif()
endforeach()
