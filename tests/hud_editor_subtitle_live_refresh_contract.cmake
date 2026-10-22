if(NOT DEFINED HUD_EDITOR_SCRIPT OR NOT EXISTS "${HUD_EDITOR_SCRIPT}")
    message(FATAL_ERROR "HUD editor script was not provided")
endif()

file(READ "${HUD_EDITOR_SCRIPT}" hud_editor)

set(required_fragments
    "function W3VRHudEditorApplySubtitleRootLayout()"
    "function W3VRHudEditorScheduleAddedSubtitleLayoutRefresh(id: int)"
    "function W3VRHudEditorTickAddedSubtitleLayoutRefresh(now: float)"
    "if (!this.w3vr_hud_editor_managed)"
    "this.w3vr_hud_editor_active_subtitle_ids.PushBack(id);"
    "this.W3VRHudEditorApplySubtitleRootLayout();"
    "[FIX:SUBTITLE-FLASH-SCALE-TARGET V1563]"
    "\"desiredScale\", root.GetMemberFlashNumber(\"scaleX\")"
    "@wrapMethod(CR4HudModuleSubtitles)"
    "function OnSubtitleAdded("
    "wrappedMethod(id, speakerNameDisplayText, htmlString, alternativeUI);"
    "this.W3VRHudEditorScheduleAddedSubtitleLayoutRefresh(id);"
    "subtitlesModule.W3VRHudEditorTickAddedSubtitleLayoutRefresh(now);"
)

foreach(fragment IN LISTS required_fragments)
    string(FIND "${hud_editor}" "${fragment}" position)
    if(position EQUAL -1)
        message(FATAL_ERROR "Missing live subtitle refresh contract: ${fragment}")
    endif()
endforeach()

string(FIND "${hud_editor}"
    "function BootstrapSubtitlePreviewLayout(" retired_preview_helper)
if(NOT retired_preview_helper EQUAL -1)
    message(FATAL_ERROR
        "The preview-only subtitle refresh must be physically replaced")
endif()

string(FIND "${hud_editor}"
    "wrappedMethod(id, speakerNameDisplayText, htmlString, alternativeUI);"
    wrapped_position)
string(FIND "${hud_editor}"
    "this.W3VRHudEditorScheduleAddedSubtitleLayoutRefresh(id);"
    refresh_position)
if(wrapped_position GREATER refresh_position)
    message(FATAL_ERROR
        "Subtitle layout must refresh after the real subtitle was added")
endif()

string(FIND "${hud_editor}" "temporaryY = savedY" retired_nudge)
if(NOT retired_nudge EQUAL -1)
    message(FATAL_ERROR "Retired subtitle nudge must not return")
endif()

message(STATUS "Live gameplay subtitle active-ID and Flash scale contract verified")
