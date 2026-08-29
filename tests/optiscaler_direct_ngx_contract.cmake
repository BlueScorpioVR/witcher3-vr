if(NOT DEFINED DXGI_PROXY_SOURCE OR NOT EXISTS "${DXGI_PROXY_SOURCE}")
    message(FATAL_ERROR "dxgi_proxy.cpp was not provided")
endif()
if(NOT DEFINED OPTISCALER_BRIDGE_INI OR
        NOT EXISTS "${OPTISCALER_BRIDGE_INI}")
    message(FATAL_ERROR "optiscaler_bridge.ini was not provided")
endif()

file(READ "${DXGI_PROXY_SOURCE}" dxgi_proxy)
file(READ "${OPTISCALER_BRIDGE_INI}" bridge_ini)

foreach(required_fragment IN ITEMS
        "build=V1414 base=V1413_launcher_optiscaler_afw_controls"
        "bool optiscaler_enabled{false};"
        "\"optiscaler_bridge.ini\", \"optiscaler\", \"enabled\", false"
        "LoadLibraryW(module_path)"
        "L\"OptiScaler.dll\""
        "? g_optiscaler_module"
        "hook_ngx_create_feature("
        "hook_ngx_evaluate_feature("
        "hook_ngx_release_feature("
        "g_sequential_dlss_peer_histories[*handle] = peer_handle;"
        "g_ngx_release_feature(peer_handle)"
        "MH_QueueEnableHook(create_target)"
        "MH_QueueEnableHook(evaluate_target)"
        "MH_QueueEnableHook(release_target)"
        "g_sl_evaluate_feature(\n        command_buffer, feature, frame_token, viewport)"
        "streamline=pass_through viewport=native_single histories=two"
        "g_config.optiscaler_enabled &&"
        "w3vr::optiscaler_jitter::normalize("
        "fsr_jitter=exact_peer_center"
        "fallback=none"
        "dispatch_clean_mono_dlss_camera_motion(")
    string(FIND "${dxgi_proxy}" "${required_fragment}" position)
    if(position EQUAL -1)
        message(FATAL_ERROR
            "Missing V1410 OptiScaler contract: ${required_fragment}")
    endif()
endforeach()

foreach(forbidden_fragment IN ITEMS
        "dlss_streamline_evaluate_callback"
        "streamline_split_viewports"
        "streamline_right_temporal_offset"
        "streamline_temporal_clip_correction"
        "streamline_viewport_for_eye"
        "V21006"
        "V21007"
        "OPTISCALER-INPUT-CONTRACT"
        "OPTISCALER-PIXEL-AUDIT"
        "g_optiscaler_contract_audit_logs"
        "OptiscalerPixelReadback"
        "arm_optiscaler_pixel_audit"
        "schedule_optiscaler_pixel_audit"
        "try_dump_optiscaler_pixel_audit"
        "GetAsyncKeyState(VK_F4)"
        "witcher3vr-v21007-optiscaler-pixel")
    string(FIND "${dxgi_proxy}" "${forbidden_fragment}" position)
    if(NOT position EQUAL -1)
        message(FATAL_ERROR
            "Superseded or diagnostic-only OptiScaler code remains: ${forbidden_fragment}")
    endif()
endforeach()

string(REGEX MATCH "enabled[ \t]*=[ \t]*0" bridge_disabled "${bridge_ini}")
if(NOT bridge_disabled)
    message(FATAL_ERROR "OptiScaler sidecar must default to disabled")
endif()

message(STATUS "V1410 clean OptiScaler direct-NGX contract verified")
