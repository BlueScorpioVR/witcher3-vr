if(NOT DEFINED DXGI_PROXY_SOURCE OR NOT EXISTS "${DXGI_PROXY_SOURCE}")
    message(FATAL_ERROR "dxgi_proxy.cpp was not provided")
endif()

file(READ "${DXGI_PROXY_SOURCE}" dxgi_proxy)

set(required_fragments
    "bool record_puredark_afw_motion_normalization_locked("
    "actual_clip_to_previous"
    "motion_finite && depth > 1e-7"
    "normalized_mvec[dispatch_id.xy] = native_motion.xy;"
    "normalized_mvec[dispatch_id.xy] = -native_motion.xy;"
    "normalized_mvec[dispatch_id.xy] = previous_uv - source_uv;"
    "rebase_clip_to_previous_projection("
    "const bool normalize_native_motion = camera.pixel_projection =="
    "slot.motion_normalization_source.texture,"
    "actual_clip_to_previous, 1,"
    "actual_clip_to_previous, 0,"
    "captured.depth.texture, depth.format,"
    "native_motion_normalized=%u"
)

foreach(fragment IN LISTS required_fragments)
    string(FIND "${dxgi_proxy}" "${fragment}" position)
    if(position EQUAL -1)
        message(FATAL_ERROR
            "Missing AFW native-motion contract: ${fragment}")
    endif()
endforeach()

foreach(forbidden_fragment IN ITEMS
        "record_puredark_afw_taau_motion_normalization_locked"
        "g_puredark_afw_taau_motion_pipeline"
        "taau_motion_heap")
    string(FIND "${dxgi_proxy}" "${forbidden_fragment}" position)
    if(NOT position EQUAL -1)
        message(FATAL_ERROR
            "Replaced TAAU-only motion branch remains: ${forbidden_fragment}")
    endif()
endforeach()

string(FIND "${dxgi_proxy}"
    "if (normalize_native_motion) {" dlss_native_begin)
if(dlss_native_begin EQUAL -1)
    message(FATAL_ERROR
        "DLSS normalization has no actual native-projection gate")
endif()
string(SUBSTRING "${dxgi_proxy}" ${dlss_native_begin} 12000 dlss_native_body)
string(FIND "${dlss_native_body}"
    "record_puredark_afw_motion_normalization_locked("
    dlss_normalizer_call)
if(dlss_normalizer_call EQUAL -1)
    message(FATAL_ERROR
        "DLSS normalization must be owned by actual native pixel provenance")
endif()

message(STATUS "AFW native motion normalization contract verified")
