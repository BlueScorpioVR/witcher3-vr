if(NOT DEFINED DXGI_PROXY_SOURCE)
    message(FATAL_ERROR "DXGI_PROXY_SOURCE is required")
endif()

file(READ "${DXGI_PROXY_SOURCE}" source)

set(required_fragments
    "build=V1509 base=V1508_aer_full_vr_scene_only_admission"
    "bool witcher_sense_history_suppression_route_active()"
    "native_asymmetric_transparent_center_route_active()"
    "constexpr UINT kWitcherSenseHistorySrvRoot = 1;"
    "constexpr UINT kWitcherSenseHistoryFocusOffset = 2;"
    "WitcherSenseDescriptorKind::Scene"
    "WitcherSenseDescriptorKind::History"
    "WitcherSenseDescriptorKind::Auxiliary"
    "witcher_sense_history_input_signature_matches(t0, t2, t3)"
    "lookup_witcher_sense_history_rtv(t2.resource, rtv_out)"
    "g_witcher_sense_history_compositor_pipeline"
    "draw_pipeline->AddRef();"
    "cached_pipeline != nullptr && cached_pipeline != draw_pipeline"
    "struct WitcherSenseHistorySuppressionDrawScope"
    "~WitcherSenseHistorySuppressionDrawScope()"
    "D3D12_RESOURCE_STATE_PIXEL_SHADER_RESOURCE"
    "D3D12_RESOURCE_STATE_RENDER_TARGET"
    "ClearRenderTargetView("
    "V1499 Witcher Sense peer-eye history suppressed"
    "WitcherSenseHistorySuppressionDrawScope\n        witcher_sense_history_suppression")

foreach(required_fragment IN LISTS required_fragments)
    string(FIND "${source}" "${required_fragment}" found)
    if(found EQUAL -1)
        message(FATAL_ERROR
            "Missing V1499 bounded Witcher Senses history contract: ${required_fragment}")
    endif()
endforeach()

string(FIND "${source}"
    "struct WitcherSenseHistorySuppressionDrawScope" feature_begin)
string(FIND "${source}"
    "void apply_hud_frame_scale()" feature_end)
if(feature_begin EQUAL -1 OR feature_end EQUAL -1 OR
   feature_end LESS_EQUAL feature_begin)
    message(FATAL_ERROR "Cannot isolate V1499 history intervention")
endif()
math(EXPR feature_length "${feature_end} - ${feature_begin}")
string(SUBSTRING "${source}" ${feature_begin} ${feature_length} feature_block)
foreach(forbidden_feature_operation
    "SetPipelineState("
    "SetGraphicsRootDescriptorTable("
    "SetGraphicsRootConstantBufferView("
    "CopyTextureRegion("
    "CreateCommittedResource("
    "CreateFence("
    "std::thread"
    "fopen_s(")
    string(FIND "${feature_block}"
        "${forbidden_feature_operation}" forbidden_found)
    if(NOT forbidden_found EQUAL -1)
        message(FATAL_ERROR
            "V1499 history path contains expanded GPU work: ${forbidden_feature_operation}")
    endif()
endforeach()

foreach(retired_fragment
    "VK_PRIOR"
    "handle_witcher_sense_history_hotkey"
    "g_witcher_sense_history_armed"
    "g_witcher_sense_history_arm_present"
    "g_witcher_sense_history_page_up_down"
    "witcher_sense_alignment_dump_route_configured"
    "WitcherSenseAlignment"
    "witcher3vr-ws-align-"
    "page_up_reusable_t0_t2_t3")
    string(FIND "${source}" "${retired_fragment}" retired_found)
    if(NOT retired_found EQUAL -1)
        message(FATAL_ERROR
            "Retired Witcher Senses trial path survived V1499: ${retired_fragment}")
    endif()
endforeach()

message(STATUS "V1499 bounded Witcher Senses history contract verified")

