if(NOT DEFINED HUD_EDITOR_SCRIPT OR NOT EXISTS "${HUD_EDITOR_SCRIPT}")
    message(FATAL_ERROR "HUD editor script was not provided")
endif()

file(READ "${HUD_EDITOR_SCRIPT}" hud_editor)

set(required_fragments
    "return \"V1260\";"
    "function W3VRHudEditorApplySubtitleRootLayout()"
    "this.OnSubtitleAdded("
    "this.W3VRHudEditorScheduleAddedSubtitleLayoutRefresh(id);"
    "[FIX:SUBTITLE-FLASH-SCALE-TARGET V1563]"
)

foreach(fragment IN LISTS required_fragments)
    string(FIND "${hud_editor}" "${fragment}" position)
    if(position EQUAL -1)
        message(FATAL_ERROR "Missing subtitle preview refresh contract: ${fragment}")
    endif()
endforeach()

string(FIND "${hud_editor}" "ReassertSubtitleLayout();" continuous_reassert)
if(NOT continuous_reassert EQUAL -1)
    message(FATAL_ERROR "V1247 must not retain V1246's per-frame reassert")
endif()

message(STATUS "HUD subtitle preview uses the active-ID root layout refresh")
