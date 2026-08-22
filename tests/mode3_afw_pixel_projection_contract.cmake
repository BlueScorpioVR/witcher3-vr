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
)

foreach(fragment IN LISTS required_fragments)
    string(FIND "${dxgi_proxy}" "${fragment}" position)
    if(position EQUAL -1)
        message(FATAL_ERROR
            "Missing AFW pixel-projection contract: ${fragment}")
    endif()
endforeach()

foreach(forbidden_fragment IN ITEMS
        "pair_centered_afw_camera_with_centered_fov"
        "fov_has_off_axis_center")
    string(FIND "${dxgi_proxy}" "${forbidden_fragment}" position)
    if(NOT position EQUAL -1)
        message(FATAL_ERROR
            "AFW projection must not be inferred from centered matrices/FOV: ${forbidden_fragment}")
    endif()
endforeach()

string(FIND "${dxgi_proxy}"
    "void capture_puredark_afw_camera(" capture_begin)
string(FIND "${dxgi_proxy}"
    "bool hydrate_streamline_dlss_callback_constants(" capture_end)
if(capture_begin EQUAL -1 OR capture_end EQUAL -1 OR
        NOT capture_begin LESS capture_end)
    message(FATAL_ERROR "Could not isolate the direct AFW camera capture")
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
