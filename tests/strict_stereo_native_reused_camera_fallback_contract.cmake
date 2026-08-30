if(NOT DEFINED DXGI_PROXY_SOURCE OR NOT EXISTS "${DXGI_PROXY_SOURCE}")
    message(FATAL_ERROR "dxgi_proxy.cpp was not provided")
endif()

file(READ "${DXGI_PROXY_SOURCE}" source)

foreach(required_fragment IN ITEMS
        "build=V1501 base=V1499_witcher_sense_expanded_partition_cache"
        "[FIX:STRICT-STEREO-PERSISTENT-REUSED-CAMERA V1488 1/4]"
        "[FIX:STRICT-STEREO-PERSISTENT-REUSED-CAMERA V1488 2/4]"
        "[FIX:STRICT-STEREO-PERSISTENT-REUSED-CAMERA V1488 3/4]"
        "[FIX:STRICT-STEREO-PERSISTENT-REUSED-CAMERA V1488 4/4]"
        "[FIX:STRICT-STEREO-NATIVE-REUSED-CAMERA-FALLBACK V1487 1/3]"
        "[FIX:STRICT-STEREO-NATIVE-REUSED-CAMERA-FALLBACK V1487 3/3]"
        "reused_camera_fallback_uses_native_asymmetric_projection({"
        "admit_native_reused_camera_pair("
        "reset_strict_stereo_reused_camera_episode(generation);"
        "strict_stereo_native_reused_camera_pair_admitted("
        "const bool native_asymmetric_reused_camera_fallback ="
        "const bool centered_reused_camera_fallback ="
        "[FIX:FULL-VR-FALLBACK-RAW-FOV V1424]"
        "xr_fov = &g_xr_views[static_cast<size_t>(eye)].fov;"
        "if (native_asymmetric_reused_camera_fallback) {"
        "native_asymmetric_full_vr_slot->factory_mask.fetch_or("
        "native_asymmetric_frame_slot->temporal_mask.fetch_or("
        "V1488 strict Stereo persistent native reused-camera"
        "if (centered_reused_camera_fallback &&"
        "centered_reused_fallback_fov_published ="
        "publish_shared_mode3_projection_fov("
        "strict_stereo_reused_camera_admission=complete_centered_proof_pair_then_native_next_pair")
    string(FIND "${source}" "${required_fragment}" fragment_position)
    if(fragment_position EQUAL -1)
        message(FATAL_ERROR
            "Missing V1487 strict-Stereo native reused-camera contract: ${required_fragment}")
    endif()
endforeach()

foreach(forbidden_fragment IN ITEMS
        "symmetric_asymmetric_full_vr_fallback"
        "frame_fallback_uses_symmetric_projection"
        "symmetric_asym_fallback="
        "V1418 opening_cutscene_asym_fallback_fov=published_after_corrected_camera_write")
    string(FIND "${source}" "${forbidden_fragment}" fragment_position)
    if(NOT fragment_position EQUAL -1)
        message(FATAL_ERROR
            "Superseded centered strict-Stereo fallback survived: ${forbidden_fragment}")
    endif()
endforeach()

string(REGEX MATCHALL
    "publish_shared_mode3_projection_fov\\(" publisher_references "${source}")
list(LENGTH publisher_references publisher_reference_count)
if(NOT publisher_reference_count EQUAL 3)
    message(FATAL_ERROR
        "Shared Mode-3 FOV must keep one owner and its two surviving AER/shared producers; found ${publisher_reference_count} references")
endif()

message(STATUS "V1488 persistent strict-Stereo reused-camera admission contract verified")
