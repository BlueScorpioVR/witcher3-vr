if(NOT DEFINED DXGI_PROXY_SOURCE)
    message(FATAL_ERROR "DXGI_PROXY_SOURCE is required")
endif()

file(READ "${DXGI_PROXY_SOURCE}" source)

foreach(required IN ITEMS
        "[TRIAL:RESHADE-COMMAND-LIST-UNWRAP V23020 1/3]"
        "[TRIAL:RESHADE-COMMAND-LIST-UNWRAP V23020 2/3]"
        "[TRIAL:RESHADE-COMMAND-LIST-UNWRAP V23020 3/3]"
        "g_reshade_command_list_native_offset"
        "g_reshade_unwrap_logs"
        "module_base_name_is(wrapper_owner, L\"ReShade64.dll\")"
        "validated_native_graphics_command_list(candidate, native)"
        "reshade_command_list_unwrap=recognized_wrapper_only"
        "native_candidate=d3d12_graphics_command_list_qi_proven"
        "w3vr_tracking=disabled")
    string(FIND "${source}" "${required}" position)
    if(position EQUAL -1)
        message(FATAL_ERROR
            "Missing V23020 ReShade command-list unwrap contract: ${required}")
    endif()
endforeach()

string(FIND "${source}"
    "if (reshade_internal_submission) {" branch_start)
string(FIND "${source}"
    "// [TRIAL:RESHADE-COMMAND-LIST-UNWRAP V23020 2/3]" marker)
string(FIND "${source}"
    "g_execute_command_lists(queue, num_command_lists, command_lists);\n        return;"
    opaque_return)
if(branch_start EQUAL -1 OR marker EQUAL -1 OR opaque_return EQUAL -1 OR
        NOT branch_start LESS marker OR NOT marker LESS opaque_return)
    message(FATAL_ERROR
        "V23020 must leave the ReShade immediate submission opaque")
endif()

string(FIND "${source}" "auto reshade_afw_pending" rejected_ticket_path)
string(FIND "${source}"
    "queue, reshade_afw_pending" rejected_ticket_publish)
if(NOT rejected_ticket_path EQUAL -1 OR NOT rejected_ticket_publish EQUAL -1)
    message(FATAL_ERROR
        "V23020 must physically remove V23019 immediate-list AFW publication")
endif()

message(STATUS "V23020 ReShade command-list unwrap contract verified")
