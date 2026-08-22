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
    "w3vr::smoke_visibility::dump_last_seconds(\"V1355\", 15)"
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
require_text(DXGI_SOURCE
    "g_real_smoke_clip_probe_pipelines[probe_variant]"
    "three exact projection probe PSOs are selected per draw")
require_text(DXGI_SOURCE
    "probe_desc.BlendState.RenderTarget[target].\n                    RenderTargetWriteMask = 0"
    "probe PSOs cannot write render targets")
require_text(DXGI_SOURCE
    "probe_desc.DepthStencilState.DepthWriteMask =\n                D3D12_DEPTH_WRITE_MASK_ZERO"
    "probe PSOs cannot write depth")
require_text(DXGI_SOURCE
    "probe_desc.DepthStencilState.StencilWriteMask = 0"
    "probe PSOs cannot write stencil")
require_text(DXGI_SOURCE
    "probe_metadata.flags |=\n                w3vr::smoke_visibility::DrawReferenceProbe"
    "probe samples are explicitly separated from rendered samples")
require_text(DXGI_SOURCE
    "auto probe_metadata = metadata"
    "rendered draw and probes share one immutable draw-group metadata record")
require_text(DXGI_SOURCE
    "g_set_pipeline_state(command_list, selected_pipeline)"
    "rendered pipeline is restored after the no-write probes")
require_text(DXGI_SOURCE
    "current_exact_engine_render_tag(producer)"
    "producer transaction is captured separately from late draw authority")
require_text(DXGI_SOURCE
    "match_native_focus_draw_eye(\n                metadata.camera_position, metadata.present,\n                fresh_authority)"
    "fresh eye authority is derived independently for the same b1 camera")
require_text(DXGI_SOURCE
    "metadata.flags |=\n                w3vr::smoke_visibility::DrawFreshEyeAuthority"
    "fresh eye authority is explicitly marked without selecting a pipeline")
require_text(DXGI_SOURCE
    "capture_graphics_pso_recipe(\n                        g_real_smoke_pso_recipe, device, *desc, info)"
    "the immutable original smoke PSO recipe is retained")
require_text(DXGI_SOURCE
    "bool ensure_real_smoke_projection_psos()"
    "missing smoke projection variants have one deferred completion owner")
require_text(DXGI_SOURCE
    "real_smoke_variant_bootstrap_allowed(\n                variant_index, runtime_views_ready)"
    "eye variants wait for valid runtime views while zero-center stays independent")
require_text(DXGI_SOURCE
    "// Complete producer-independent smoke variants after OpenXR view discovery"
    "the Present boundary completes preparation independently of startup mode")

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

require_text(RECORDER
    "group=%llu sample=%s"
    "dump exposes exact A/B draw grouping")
require_text(RECORDER
    "metadata.clip_matrix[15]"
    "dump includes the complete b1 clip matrix")
require_text(RECORDER
    "# eye_authority actual_cache=%llu fresh_match=%llu agree=%llu mismatch=%llu"
    "dump summarizes mutable-cache versus fresh eye authority")
require_text(RECORDER
    "fresh=%u:%d:%llu:%.9g:%.9g"
    "each row includes fresh route eye pair distance and margin")

message(STATUS "V1355 smoke eye-authority A/B recorder contract verified")
