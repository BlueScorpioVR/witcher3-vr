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
        "build=V1441 base=V1424_noaa_safe_optimization"
        "bool optiscaler_enabled{false};"
        "\"optiscaler_bridge.ini\", \"optiscaler\", \"enabled\", false"
        "bool native_dlss_public_streamline_owner_active()"
        "temporal_backend_is_dlss() && !g_config.optiscaler_enabled"
        "bool optiscaler_private_ngx_owner_active()"
        "temporal_backend_is_dlss() && g_config.optiscaler_enabled"
        "streamline_viewport_for_eye("
        "capture_streamline_dlss_callback_resource("
        "hydrate_streamline_dlss_callback_constants("
        "resubmit_streamline_native_asymmetric_dlss_jitter("
        "finalize_dlss_cache_submission(command_list, completion_result)"
        "commit_streamline_native_asymmetric_dlss_input("
        "HMODULE module = g_optiscaler_module;"
        "hook_ngx_create_feature("
        "hook_ngx_evaluate_feature("
        "hook_ngx_release_feature("
        "MH_QueueEnableHook(create_target)"
        "MH_QueueEnableHook(evaluate_target)"
        "MH_QueueEnableHook(release_target)"
        "owner=private_direct_ngx backend=optiscaler"
        "native_nvngx_direct_hooks=absent"
        "fallback=none"
        "dispatch_clean_mono_dlss_camera_motion(")
    string(FIND "${dxgi_proxy}" "${required_fragment}" position)
    if(position EQUAL -1)
        message(FATAL_ERROR
            "Missing V1418 DLSS owner-isolation contract: ${required_fragment}")
    endif()
endforeach()

foreach(forbidden_fragment IN ITEMS
        "GetModuleHandleW(L\"nvngx_dlss.dll\")"
        "private_direct_ngx backend=native"
        "g_config.optiscaler_enabled ? \"optiscaler\" : \"native\""
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
            "Forbidden native-NGX or diagnostic path remains: ${forbidden_fragment}")
    endif()
endforeach()

string(REGEX MATCH "enabled[ \t]*=[ \t]*0" bridge_disabled "${bridge_ini}")
if(NOT bridge_disabled)
    message(FATAL_ERROR "OptiScaler sidecar must default to disabled")
endif()

message(STATUS "V1418 native Streamline / OptiScaler-only NGX contract verified")
