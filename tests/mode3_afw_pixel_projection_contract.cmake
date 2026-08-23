if(NOT DEFINED DXGI_PROXY_SOURCE OR NOT EXISTS "${DXGI_PROXY_SOURCE}")
    message(FATAL_ERROR "dxgi_proxy.cpp was not provided")
endif()

file(READ "${DXGI_PROXY_SOURCE}" dxgi_proxy)

set(required_fragments
    "completed_engine_frame_pixel_projection("
    "tag.pixel_projection = completed_engine_frame_pixel_projection("
    "route_tag.pixel_projection, route_tag.render_view.fov,"
    "projection_authority.encoding =="
    "AfwPixelProjection::NativeAsymmetric"
    "captured.pixel_projection = projection_authority.encoding;"
    "captured.pixel_projection = camera.pixel_projection;"
    "recovered_camera.pixel_projection = pixel_projection;"
    "result.pixel_projection = captured.pixel_projection;"
    "pair.afw_pixel_projection = afw_projection_authority.encoding;"
    "out.afw_pixel_projection = current.afw_pixel_projection;"
    "hmd_motion.afw_pixel_projection"
    "puredark_afw.pixel_projection !="
    "puredark_afw.pixel_projection =="
    "g_mode3_afw_sequenced_native_asymmetric ="
    "puredark_pair_native_asymmetric;"
    "native_asymmetric_source_views_valid"
    "mode3_common_afw_sequenced_available"
    "stereo_cached &&"
    "bool rebuild_puredark_afw_native_projection_pair("
    "aer_reference_views, routed_eye, captured.camera,"
    "recovered = rebuild_puredark_afw_native_projection_pair("
    "exact_render_views, eye, recovered_camera.camera,"
)

foreach(fragment IN LISTS required_fragments)
    string(FIND "${dxgi_proxy}" "${fragment}" position)
    if(position EQUAL -1)
        message(FATAL_ERROR
            "Missing AFW pixel-projection contract: ${fragment}")
    endif()
endforeach()

string(FIND "${dxgi_proxy}"
    "native_asymmetric_noaa_route_active() &&\n                    packed_stereo_available &&"
    stale_packed_only_preflight)
if(NOT stale_packed_only_preflight EQUAL -1)
    message(FATAL_ERROR
        "AER native-ASym preflight regressed to the packed-only source")
endif()

foreach(forbidden_fragment IN ITEMS
        "pair_centered_afw_camera_with_centered_fov"
        "fov_has_off_axis_center"
        "final_source_already_compensated")
    string(FIND "${dxgi_proxy}" "${forbidden_fragment}" position)
    if(NOT position EQUAL -1)
        message(FATAL_ERROR
            "AFW projection must not be inferred from centered matrices/FOV: ${forbidden_fragment}")
    endif()
endforeach()

string(FIND "${dxgi_proxy}"
    "void capture_puredark_afw_camera(" capture_begin)
string(FIND "${dxgi_proxy}"
    "int32_t capture_puredark_afw_dlss_inputs_from_resources(" capture_end)
if(capture_begin EQUAL -1 OR capture_end EQUAL -1 OR
        NOT capture_begin LESS capture_end)
    message(FATAL_ERROR "Could not isolate the direct AFW camera capture")
endif()

string(FIND "${dxgi_proxy}"
    "bool capture_puredark_afw_mode3_taau_inputs(" taau_capture_begin)
string(FIND "${dxgi_proxy}"
    "HMODULE module_owning_address(" taau_capture_end)
if(taau_capture_begin EQUAL -1 OR taau_capture_end EQUAL -1 OR
        NOT taau_capture_begin LESS taau_capture_end)
    message(FATAL_ERROR "Could not isolate the TAAU AFW camera capture")
endif()
math(EXPR taau_capture_length
    "${taau_capture_end} - ${taau_capture_begin}")
string(SUBSTRING "${dxgi_proxy}" ${taau_capture_begin}
    ${taau_capture_length} taau_capture_body)
string(FIND "${taau_capture_body}"
    "pixel_projection ==\n            w3vr::mode3_transport::AfwPixelProjection::NativeAsymmetric"
    taau_native_gate)
string(FIND "${taau_capture_body}"
    "rebuild_puredark_afw_native_projection_pair(" taau_absolute_projection)
if(taau_native_gate EQUAL -1 OR taau_absolute_projection EQUAL -1 OR
        NOT taau_native_gate LESS taau_absolute_projection)
    message(FATAL_ERROR
        "Native TAAU AFW must rebuild the complete frozen projection pair")
endif()
math(EXPR capture_length "${capture_end} - ${capture_begin}")
string(SUBSTRING "${dxgi_proxy}" ${capture_begin} ${capture_length}
    capture_body)
string(FIND "${capture_body}"
    "native_asymmetric_noaa_route_active())" requested_mode_classifier)
if(NOT requested_mode_classifier EQUAL -1)
    message(FATAL_ERROR
        "Direct AFW camera capture must branch on actual producer encoding, not the live F2 request")
endif()

message(STATUS "Mode-3 AFW pixel-projection contract verified")
