if(NOT DEFINED DXGI_PROXY_SOURCE OR NOT EXISTS "${DXGI_PROXY_SOURCE}")
    message(FATAL_ERROR "dxgi_proxy.cpp was not provided")
endif()

file(READ "${DXGI_PROXY_SOURCE}" source)

foreach(required_fragment IN ITEMS
        "build=V1511 base=V1509_witcher_sense_aligned_extent"
        "[FIX:AER-CINEMA-NATIVE-ASYM-PAIR-AUTHORITY V1507 1/6]"
        "[FIX:AER-CINEMA-NATIVE-ASYM-PAIR-AUTHORITY V1507 2/6]"
        "[FIX:AER-CINEMA-NATIVE-ASYM-PAIR-AUTHORITY V1507 3/6]"
        "[FIX:AER-CINEMA-NATIVE-ASYM-PAIR-AUTHORITY"
        "V1507 4/6]"
        "[FIX:AER-CINEMA-NATIVE-ASYM-PAIR-AUTHORITY V1507 5/6]"
        "[FIX:AER-CINEMA-NATIVE-ASYM-PAIR-AUTHORITY V1507 6/6]"
        "g_mode3_reused_camera_episode"
        "reset_mode3_reused_camera_episode("
        "mode3_native_reused_camera_pair_admitted("
        "reused_camera_fallback_uses_native_asymmetric_projection({"
        "g_sequential_cinema_pair_native_asymmetric"
        "cinema_pair_admissible({"
        "const bool temporal_backend_active ="
        "sequential_views_complete"
        "g_sequential_cinema_pair_native_asymmetric ="
        "cinema_presentation_uses_native_asymmetric({"
        "mode3_source_projection_ready &&"
        "g_sequential_cinema_pair_native_asymmetric;"
        "V1507 aer_full_vr_projection=stereo_native_asym_contract"
        "dump_last_seconds(\"V1511\", 15)")
    string(FIND "${source}" "${required_fragment}" fragment_position)
    if(fragment_position EQUAL -1)
        message(FATAL_ERROR
            "Missing V1507 Mode3 native reused-camera/AER pair contract: ${required_fragment}")
    endif()
endforeach()

foreach(forbidden_fragment IN ITEMS
        "g_strict_stereo_reused_camera_episode"
        "reset_strict_stereo_reused_camera_episode("
        "strict_stereo_native_reused_camera_pair_admitted("
        "aer=centered_sequential_unchanged"
        "AER retains its separate sequential centered producer"
        "repaired centered pair through the packed")
    string(FIND "${source}" "${forbidden_fragment}" fragment_position)
    if(NOT fragment_position EQUAL -1)
        message(FATAL_ERROR
            "Superseded strict-Stereo/AER-centered path survived: ${forbidden_fragment}")
    endif()
endforeach()

string(FIND "${source}"
    "bool native_asymmetric_full_vr_effect_source_active() {"
    effect_source_begin)
if(effect_source_begin EQUAL -1)
    message(FATAL_ERROR "Missing native Full-VR effect-source authority")
endif()
string(SUBSTRING "${source}" ${effect_source_begin} -1 effect_source_tail)
string(FIND "${effect_source_tail}"
    "std::atomic<uint32_t> g_ngx_trace_count" effect_source_end)
if(effect_source_end EQUAL -1)
    message(FATAL_ERROR "Could not bound native Full-VR effect-source authority")
endif()
string(SUBSTRING "${effect_source_tail}" 0 ${effect_source_end}
    effect_source_body)
string(FIND "${effect_source_body}" "mode3_aer_presentation_active()"
    aer_effect_exclusion)
if(NOT aer_effect_exclusion EQUAL -1)
    message(FATAL_ERROR
        "AER still excludes the reused-camera native effect lifetime")
endif()

message(STATUS "V1507 Mode3 native reused-camera and AER Cinema pair authority contract verified")
