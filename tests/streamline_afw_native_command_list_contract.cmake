if(NOT DEFINED DXGI_PROXY_SOURCE OR NOT EXISTS "${DXGI_PROXY_SOURCE}")
    message(FATAL_ERROR "dxgi_proxy.cpp was not provided")
endif()

file(READ "${DXGI_PROXY_SOURCE}" dxgi_proxy)

foreach(required_fragment IN ITEMS
        "[FIX:STREAMLINE-AFW-NATIVE-RECORDING V1365 1/3]"
        "command_list_is_d3d12_runtime(command_list)"
        "AFW motion normalization requires a native D3D12 command list"
        "[FIX:STREAMLINE-AFW-NATIVE-RECORDING V1365 2/3]"
        "ID3D12GraphicsCommandList* const afw_recording_command_list ="
        "resolve_native_command_list(command_list);"
        "capture_puredark_afw_dlss_inputs_from_resources(\n                    afw_recording_command_list,"
        "[FIX:STREAMLINE-AFW-NATIVE-RECORDING V1365 3/3]"
        "g_sl_evaluate_feature(\n        command_buffer, feature, frame_token, routed_viewport)"
        "V1365 streamline_afw_recording=native_unwrapped")
    string(FIND "${dxgi_proxy}" "${required_fragment}" position)
    if(position EQUAL -1)
        message(FATAL_ERROR
            "Missing V1365 Streamline AFW command-list contract: ${required_fragment}")
    endif()
endforeach()

string(FIND "${dxgi_proxy}"
    "int __fastcall hook_sl_evaluate_feature(" hook_begin)
if(hook_begin EQUAL -1)
    message(FATAL_ERROR "Missing Streamline evaluate hook")
endif()
string(SUBSTRING "${dxgi_proxy}" ${hook_begin} 12000 hook_body)

string(FIND "${hook_body}"
    "capture_puredark_afw_dlss_inputs_from_resources(\n                    command_list,"
    wrapped_capture)
if(NOT wrapped_capture EQUAL -1)
    message(FATAL_ERROR
        "Public Streamline wrapper still reaches the AFW capture path")
endif()

message(STATUS "V1365 Streamline AFW native command-list contract verified")
