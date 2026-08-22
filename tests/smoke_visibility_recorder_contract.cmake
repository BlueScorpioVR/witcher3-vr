if(NOT DEFINED DXGI_PROXY_SOURCE OR NOT DEFINED RECORDER_SOURCE)
    message(FATAL_ERROR "smoke visibility contract requires both source paths")
endif()

file(READ "${DXGI_PROXY_SOURCE}" DXGI_SOURCE)
file(READ "${RECORDER_SOURCE}" RECORDER)

function(require_text haystack needle description)
    string(FIND "${${haystack}}" "${needle}" found)
    if(found EQUAL -1)
        message(FATAL_ERROR "missing smoke visibility contract: ${description}")
    endif()
endfunction()

require_text(DXGI_SOURCE
    "real_smoke_pipeline ==\n            g_real_smoke_pipeline.load"
    "exact canonical smoke PSO admission")
require_text(DXGI_SOURCE
    "w3vr::smoke_visibility::begin_draw"
    "query begins around the admitted draw")
require_text(DXGI_SOURCE
    "w3vr::smoke_visibility::end_draw(command_list, token)"
    "query ends after the admitted draw")
require_text(DXGI_SOURCE
    "w3vr::smoke_visibility::on_command_list_reset(command_list)"
    "reset abandons unsubmitted samples")
require_text(DXGI_SOURCE
    "w3vr::smoke_visibility::on_execute("
    "real queue submission owns GPU readiness")
require_text(DXGI_SOURCE
    "w3vr::smoke_visibility::dump_last_seconds(\"V1350\", 15)"
    "shared F3 edge dumps the focused recorder")
require_text(DXGI_SOURCE
    "resolve_real_smoke_cbv(*state, 1, cbv)"
    "exact b1 matrix is captured")
require_text(DXGI_SOURCE
    "pipeline.cull_mode"
    "rasterizer cull state is captured")
require_text(DXGI_SOURCE
    "state->viewport_count"
    "viewport state is captured")
require_text(DXGI_SOURCE
    "state->scissor_count"
    "scissor state is captured")

require_text(RECORDER
    "D3D12_QUERY_HEAP_TYPE_PIPELINE_STATISTICS"
    "pipeline-statistics query heap")
require_text(RECORDER
    "statistics.GSPrimitives"
    "geometry emission counter")
require_text(RECORDER
    "statistics.CPrimitives"
    "post-clip primitive counter")
require_text(RECORDER
    "statistics.PSInvocations"
    "pixel invocation counter")
require_text(RECORDER
    "wait_for_queue(queue)"
    "F3 waits for submitted query completion")

message(STATUS "V1350 inherited exact smoke visibility recorder contract verified")
