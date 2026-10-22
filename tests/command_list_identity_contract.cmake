file(READ "${DXGI_PROXY_SOURCE}" source)
get_filename_component(source_dir "${DXGI_PROXY_SOURCE}" DIRECTORY)
file(READ "${source_dir}/command_list_identity.cpp" identity)
file(READ "${source_dir}/command_list_identity.h" identity_header)

foreach(required IN ITEMS
        "[FIX:NESTED-COMMAND-LIST-IDENTITY V1532 1/3]"
        "[FIX:NESTED-COMMAND-LIST-IDENTITY V1532 2/3]"
        "[FIX:NESTED-COMMAND-LIST-IDENTITY V1532 3/3]"
        "w3vr::command_list_identity::resolve("
        "classify_command_list_owner"
        "V1532 command_list_identity=streamline_reshade_qi_chain"
        "native_candidate=d3d12_graphics_command_list_qi_proven"
        "resolve_execution_command_list(wrapped_command_list)"
        "[FIX:RENDERDOC-COMMAND-LIST-ENDPOINT V1544 1/3]"
        "[FIX:RENDERDOC-COMMAND-LIST-ENDPOINT V1544 2/3]"
        "[FIX:RENDERDOC-COMMAND-LIST-ENDPOINT V1544 3/3]"
        "[FIX:RENDERDOC-INTERNAL-BARRIER-BYPASS V1545 1/1]"
        "module_base_name_is(owner, L\"renderdoc.dll\")"
        "module_owning_address(_ReturnAddress()) == g_renderdoc_module"
        "return Owner::RenderDoc;"
        "owner == Owner::Native || owner == Owner::RenderDoc"
        "command_list_is_recording_endpoint(command_list)"
        "w3vr_tracking=disabled")
    string(FIND "${source}" "${required}" position)
    if(position EQUAL -1)
        message(FATAL_ERROR "Missing nested command-list identity contract: ${required}")
    endif()
endforeach()
foreach(retired IN ITEMS g_streamline_command_list_native_offset
        g_reshade_command_list_native_offset kMaxWrapperScanBytes
        validated_native_graphics_command_list "producer join will use the wrapper"
        "auto reshade_afw_pending" "queue, reshade_afw_pending"
        "resolve_native_command_list" "command_list_is_d3d12_runtime")
    string(FIND "${source}" "${retired}" position)
    if(NOT position EQUAL -1)
        message(FATAL_ERROR "Retired command-list path remains: ${retired}")
    endif()
endforeach()
foreach(required IN ITEMS "kStreamlineBase : kReShadeBase" "Failure::Cycle"
        "Failure::Depth" "Failure::UnknownOwner" "graphics->Release();"
        "values[--count]->Release();" "classify(graphics) == owner"
        "Owner::Native || owner == Owner::RenderDoc")
    string(FIND "${identity}" "${required}" position)
    if(position EQUAL -1)
        message(FATAL_ERROR "Missing COM chain validation/lifetime: ${required}")
    endif()
endforeach()
string(FIND "${identity_header}" "ID3D12GraphicsCommandList* endpoint{};" endpoint_field)
if(endpoint_field EQUAL -1)
    message(FATAL_ERROR "Missing execution-endpoint result field")
endif()
string(FIND "${source}" "if (reshade_internal_submission) {" branch_start)
string(FIND "${source}"
    "// [FIX:NESTED-COMMAND-LIST-IDENTITY V1532 2/3]" marker)
string(FIND "${source}"
    "g_execute_command_lists(queue, num_command_lists, command_lists);\n        return;"
    opaque_return)
if(branch_start EQUAL -1 OR marker EQUAL -1 OR opaque_return EQUAL -1 OR
        NOT branch_start LESS marker OR NOT marker LESS opaque_return)
    message(FATAL_ERROR "ReShade immediate submission must remain opaque")
endif()
message(STATUS "V1532 nested identity and opaque ReShade submission verified")
