if(NOT DEFINED DXGI_PROXY_SOURCE)
    message(FATAL_ERROR "DXGI_PROXY_SOURCE is required")
endif()

file(READ "${DXGI_PROXY_SOURCE}" source)

set(required_fragments
    "[TRIAL:RESHADE-IMMEDIATE-LIST-ISOLATION V23001 1/4]"
    "[TRIAL:RESHADE-IMMEDIATE-LIST-ISOLATION V23001 2/4]"
    "[TRIAL:RESHADE-IMMEDIATE-LIST-ISOLATION V23001 3/4]"
    "[TRIAL:RESHADE-IMMEDIATE-LIST-ISOLATION V23001 4/4]"
    "WKPDID_D3DDebugObjectNameW"
    "ReShade immediate command list"
    "gpu_submission=unchanged"
    "V23001 reshade_immediate_list=exact_debug_name"
    "[FIX:RESHADE-DEFERRED-NAME-CLASSIFICATION V23033 1/2]"
    "[FIX:RESHADE-DEFERRED-NAME-CLASSIFICATION V23033 2/2]"
    "V23033 reshade_immediate_classification=positive_only"
    "classification=positive_only"
    "g_execute_command_lists(queue, num_command_lists, command_lists);"
)

foreach(required IN LISTS required_fragments)
    string(FIND "${source}" "${required}" position)
    if(position EQUAL -1)
        message(FATAL_ERROR
            "Missing V23001 ReShade immediate-list isolation contract: ${required}")
    endif()
endforeach()

string(REGEX MATCHALL
    "is_reshade_immediate_command_list\\(command_list\\)"
    command_list_bypasses "${source}")
list(LENGTH command_list_bypasses bypass_count)
if(bypass_count LESS 17)
    message(FATAL_ERROR
        "V23001 must bypass every hooked command-list tracker; found only ${bypass_count}")
endif()

string(FIND "${source}"
    "g_reshade_command_list_classification.insert(command_list).second;"
    positive_cache_position)
if(positive_cache_position EQUAL -1)
    message(FATAL_ERROR
        "V23033 must cache the exact positive raw command-list identity")
endif()

foreach(forbidden IN ITEMS
        "g_reshade_command_list_classification[command_list] = is_internal;"
        "g_reshade_last_classified_command_list_is_internal")
    string(FIND "${source}" "${forbidden}" forbidden_position)
    if(NOT forbidden_position EQUAL -1)
        message(FATAL_ERROR
            "V23033 must not retain a negative ReShade classification: ${forbidden}")
    endif()
endforeach()

message(STATUS
    "V23033 ReShade deferred-name command-list isolation contract verified")
