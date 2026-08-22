if(NOT DEFINED DXGI_PROXY_SOURCE OR NOT EXISTS "${DXGI_PROXY_SOURCE}")
    message(FATAL_ERROR "dxgi_proxy.cpp was not provided")
endif()

file(READ "${DXGI_PROXY_SOURCE}" dxgi_proxy)

set(required_fragments
    "g_runtime_mode3_projection_toggle_requests.fetch_add("
    "decide_runtime_projection_transition("
    "g_streamline_capture_generation.fetch_add(1) + 1"
    "reset_puredark_afw_publication_state();"
    "g_mode3_taau_projection_reset_mask.store("
    "g_mode3_dlss_projection_reset_mask.store("
    "route_tag.pixel_projection, route_tag.render_view.fov,"
    "projection_authority.fovs[routed_eye]"
    "projection_authority.fovs[destination_eye]"
    "aer_reference_views[routed_eye].fov = source_fov;"
    "aer_reference_views[destination_eye].fov = destination_fov;"
    "g_stereo_eye_cache_projection_valid[0] = false;"
    "g_packed_present_cache_valid = false;"
    "reset_mode3_aer_presentation_state(generation, false);"
    "g_runtime_native_stereo.store("
    "apply_present_boundary_requests();"
)

foreach(fragment IN LISTS required_fragments)
    string(FIND "${dxgi_proxy}" "${fragment}" position)
    if(position EQUAL -1)
        message(FATAL_ERROR
            "Missing Mode-3 projection transition contract: ${fragment}")
    endif()
endforeach()

string(FIND "${dxgi_proxy}"
    "destination_fov = aer_reference_views[destination_eye].fov;"
    raw_peer_fov_position)
if(NOT raw_peer_fov_position EQUAL -1)
    message(FATAL_ERROR
        "AFW peer FOV must come from the frozen native-asymmetric pair")
endif()

string(FIND "${dxgi_proxy}"
    "void apply_present_boundary_requests()" boundary_begin)
if(boundary_begin EQUAL -1)
    message(FATAL_ERROR "Missing Present-boundary request consumer")
endif()
string(SUBSTRING "${dxgi_proxy}" ${boundary_begin} -1 boundary_body)
string(FIND "${boundary_body}"
    "apply_engine_dual_render_transition(" reset_position)
string(FIND "${boundary_body}"
    "g_runtime_native_stereo.store(" publish_position)
if(reset_position EQUAL -1 OR publish_position EQUAL -1 OR
        NOT reset_position LESS publish_position)
    message(FATAL_ERROR
        "Producer selection must publish only after the canonical reset")
endif()

string(FIND "${dxgi_proxy}"
    "HRESULT STDMETHODCALLTYPE hook_present(" present_begin)
if(present_begin EQUAL -1)
    message(FATAL_ERROR "Missing hook_present")
endif()
string(SUBSTRING "${dxgi_proxy}" ${present_begin} -1 present_body)
string(FIND "${present_body}"
    "render_openxr_test_frame(" submit_position)
string(FIND "${present_body}"
    "apply_present_boundary_requests();" boundary_position)
if(submit_position EQUAL -1 OR boundary_position EQUAL -1 OR
        NOT submit_position LESS boundary_position)
    message(FATAL_ERROR
        "Projection transition must run after the current OpenXR submit")
endif()

message(STATUS "Mode-3 projection transition contract verified")
