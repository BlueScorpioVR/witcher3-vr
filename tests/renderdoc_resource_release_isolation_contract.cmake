if(NOT DEFINED DXGI_PROXY_SOURCE)
    message(FATAL_ERROR "DXGI_PROXY_SOURCE is required")
endif()

file(READ "${DXGI_PROXY_SOURCE}" source)

foreach(required_fragment IN ITEMS
        "[FIX:RENDERDOC-WRAPPED-RESOURCE-RELEASE-ISOLATION V1543]"
        "g_config.renderdoc_capture_enabled &&"
        "g_config.renderdoc_streamline_device_bridge;"
        "if (renderdoc_wrapped_device) {"
        "V1543 RenderDoc bridge isolation skipped"
        "} else {"
        "reinterpret_cast<void*>(&hook_resource_release)"
        "reinterpret_cast<void*>(&hook_resource_map)"
        "reinterpret_cast<void*>(&hook_resource_unmap)")
    string(FIND "${source}" "${required_fragment}" fragment_position)
    if(fragment_position EQUAL -1)
        message(FATAL_ERROR
            "Missing V1543 RenderDoc Release-isolation contract: ${required_fragment}")
    endif()
endforeach()
