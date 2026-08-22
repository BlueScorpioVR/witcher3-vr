if(NOT DEFINED DXGI_PROXY_SOURCE OR NOT EXISTS "${DXGI_PROXY_SOURCE}")
    message(FATAL_ERROR "dxgi_proxy.cpp was not provided")
endif()

file(READ "${DXGI_PROXY_SOURCE}" dxgi_proxy)

set(required_fragments
    "void reset_mode3_hud_publication_state(uint32_t generation)"
    "g_mode3_scene_only_draw_generations.clear();"
    "g_mode3_aer_afw_pending_hud_tags.clear();"
    "g_mode3_aer_afw_submitted_hud_tags.clear();"
    "reset_mode3_early_hud_generation_locked(generation);"
    "reset_mode3_hud_publication_state(generation);"
    "void arm_mode3_hud_generation_drain(uint32_t generation)"
    "void service_mode3_hud_generation_drain()"
    "g_mode3_hud_generation_drain_pending.store("
    "pending.destination_was_shader_read;"
    "g_mode3_early_hud_pending_by_command_list.erase(found);"
    "destination_was_shader_read};"
    "bool capture_hud_composite_pso_recipe("
    "bool ensure_asymmetric_bootstrap_hud_psos()"
    "ensure_asymmetric_bootstrap_hud_psos();"
    "V1335 deferred asymmetric HUD ready"
)

foreach(fragment IN LISTS required_fragments)
    string(FIND "${dxgi_proxy}" "${fragment}" position)
    if(position EQUAL -1)
        message(FATAL_ERROR
            "Missing Mode-3 HUD projection lifecycle contract: ${fragment}")
    endif()
endforeach()

string(FIND "${dxgi_proxy}"
    "bool derive_asymmetric_bootstrap_hud_source_shifts(" derive_begin)
string(FIND "${dxgi_proxy}"
    "bool copy_hud_pso_shader_bytecode(" derive_end)
if(derive_begin EQUAL -1 OR derive_end EQUAL -1 OR
        NOT derive_begin LESS derive_end)
    message(FATAL_ERROR "Cannot isolate asymmetric HUD geometry derivation")
endif()
math(EXPR derive_length "${derive_end} - ${derive_begin}")
string(SUBSTRING "${dxgi_proxy}" ${derive_begin} ${derive_length} derive_body)
string(FIND "${derive_body}"
    "native_asymmetric_noaa_route_active()" current_projection_gate)
if(NOT current_projection_gate EQUAL -1)
    message(FATAL_ERROR
        "Deferred HUD PSO geometry must not depend on the current F2 projection")
endif()
string(FIND "${derive_body}"
    "mode3_stereo_transport_active()" stereo_route_gate)
if(stereo_route_gate EQUAL -1)
    message(FATAL_ERROR
        "Asymmetric HUD PSO geometry must remain strict-Stereo only")
endif()

string(FIND "${dxgi_proxy}"
    "void apply_engine_dual_render_transition(" transition_begin)
string(FIND "${dxgi_proxy}"
    "size_t copy_readable_scene_descriptor(" transition_end)
if(transition_begin EQUAL -1 OR transition_end EQUAL -1 OR
        NOT transition_begin LESS transition_end)
    message(FATAL_ERROR "Cannot isolate projection transition")
endif()
math(EXPR transition_length "${transition_end} - ${transition_begin}")
string(SUBSTRING "${dxgi_proxy}" ${transition_begin}
    ${transition_length} transition_body)
string(FIND "${transition_body}"
    "if (strict_stereo_projection_reset) {\n        arm_mode3_hud_generation_drain(generation);"
    hud_reset_position)
string(FIND "${transition_body}"
    "if (!strict_stereo_projection_reset) {\n        g_engine_hmd_camera_last_present.store("
    camera_preservation_position)
if(hud_reset_position EQUAL -1 OR camera_preservation_position EQUAL -1)
    message(FATAL_ERROR
        "F2 must revoke HUD publications without invalidating Cinema authority")
endif()

string(FIND "${dxgi_proxy}"
    "if (g_mode3_hud_generation_drain_pending.load(\n                std::memory_order_acquire) == generation) {\n            return false;"
    capture_drain_guard)
string(FIND "${dxgi_proxy}"
    "if (g_mode3_early_hud_pending_by_command_list.find(command_list) !=\n        g_mode3_early_hud_pending_by_command_list.end()) {\n        return false;"
    immutable_capture_guard)
string(FIND "${dxgi_proxy}"
    "if (!projection_toggle && requested_mode < 0) {\n        service_mode3_hud_generation_drain();"
    boundary_drain_service)
if(capture_drain_guard EQUAL -1 OR immutable_capture_guard EQUAL -1 OR
        boundary_drain_service EQUAL -1)
    message(FATAL_ERROR
        "F2 HUD generations must drain before one immutable capture epoch is rebuilt")
endif()

string(FIND "${dxgi_proxy}"
    "HRESULT STDMETHODCALLTYPE hook_present(IDXGISwapChain* swapchain"
    present_begin)
if(present_begin EQUAL -1)
    message(FATAL_ERROR "Missing hook_present")
endif()
string(SUBSTRING "${dxgi_proxy}" ${present_begin} -1 present_body)
string(FIND "${present_body}"
    "ensure_asymmetric_bootstrap_hud_psos();" ensure_position)
string(FIND "${present_body}"
    "apply_present_boundary_requests();" boundary_position)
if(ensure_position EQUAL -1 OR boundary_position EQUAL -1 OR
        NOT ensure_position LESS boundary_position)
    message(FATAL_ERROR
        "Deferred HUD PSOs must be ready before publishing an F2 transition")
endif()

string(FIND "${dxgi_proxy}"
    "void STDMETHODCALLTYPE hook_set_pipeline_state(\n    ID3D12GraphicsCommandList* command_list,\n    ID3D12PipelineState* pipeline_state) {\n    if (mode3_aer_presentation_active())"
    hud_hook_begin)
if(hud_hook_begin EQUAL -1)
    message(FATAL_ERROR "Missing HUD pipeline hook")
endif()
string(SUBSTRING "${dxgi_proxy}" ${hud_hook_begin} -1 hud_hook_body)
foreach(eye IN ITEMS 0 1)
    string(FIND "${hud_hook_body}"
        "g_asymmetric_hud_composite_eye${eye}_pso.load("
        asymmetric_eye_begin)
    if(asymmetric_eye_begin EQUAL -1)
        message(FATAL_ERROR "Missing ASYM HUD eye ${eye} selection")
    endif()
    string(SUBSTRING "${hud_hook_body}" ${asymmetric_eye_begin} 500
        asymmetric_eye_body)
    string(FIND "${asymmetric_eye_body}"
        "bound_pipeline_state = pipeline_state;" safe_fallback)
    string(FIND "${asymmetric_eye_body}"
        "g_hud_composite_eye${eye}_pso.load(" symmetric_fallback)
    if(safe_fallback EQUAL -1 OR
            (NOT symmetric_fallback EQUAL -1 AND
                symmetric_fallback LESS safe_fallback))
        message(FATAL_ERROR
            "ASYM HUD eye ${eye} must fail open on the original PSO, never its SYM eye PSO")
    endif()
endforeach()

message(STATUS "Mode-3 HUD projection lifecycle contract verified")
