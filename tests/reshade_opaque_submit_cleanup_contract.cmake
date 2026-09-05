if(NOT DEFINED DXGI_PROXY_SOURCE)
    message(FATAL_ERROR "DXGI_PROXY_SOURCE is required")
endif()

file(READ "${DXGI_PROXY_SOURCE}" source)

foreach(required IN ITEMS
        "[TRIAL:RESHADE-OPAQUE-SUBMIT-CLEANUP V23011]"
        "ReShade immediate command list"
        "is_reshade_immediate_command_list"
        "GetAsyncKeyState(VK_CONTROL)"
        "hotkey=Ctrl+F6")
    string(FIND "${source}" "${required}" position)
    if(position EQUAL -1)
        message(FATAL_ERROR "Missing V23011 opaque-submit contract: ${required}")
    endif()
endforeach()

foreach(forbidden IN ITEMS
        "wait_for_reshade_present_gpu_completion"
        "execute_reshade_immediate_with_gpu_brackets"
        "WriteBufferImmediate"
        "g_reshade_gpu_marker_readback"
        "is_dlssnr_gpu_operation_callsite")
    string(FIND "${source}" "${forbidden}" position)
    if(NOT position EQUAL -1)
        message(FATAL_ERROR "V23011 retained a superseded GPU perturbation: ${forbidden}")
    endif()
endforeach()

message(STATUS "V23011 ReShade opaque-submit cleanup contract verified")
