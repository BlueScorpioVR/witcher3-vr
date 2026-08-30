if(NOT DEFINED DXGI_PROXY_SOURCE OR NOT EXISTS "${DXGI_PROXY_SOURCE}")
    message(FATAL_ERROR "dxgi_proxy.cpp was not provided")
endif()

file(READ "${DXGI_PROXY_SOURCE}" source)

foreach(required_fragment IN ITEMS
        "build=V1509 base=V1508_aer_full_vr_scene_only_admission"
        "[FIX:FULL-VR-TRANSPARENT-FIX-ADMISSION V1484 1/3]"
        "[FIX:FULL-VR-TRANSPARENT-FIX-ADMISSION V1484 2/3]"
        "[FIX:FULL-VR-TRANSPARENT-FIX-ADMISSION V1484 3/3]"
        "bool native_asymmetric_full_vr_effect_source_active()"
        "full_vr_scene,"
        "native_asymmetric_full_vr_effect_source_active());"
        "V1484 full_vr_transparent_fix=exact_native_asymmetric_source_only"
        "centered_fallback=excluded cinema_panel=excluded"
        "tiled_light=unchanged base=V1483"
        "dump_last_seconds(\"V1509\", 15)")
    string(FIND "${source}" "${required_fragment}" fragment_position)
    if(fragment_position EQUAL -1)
        message(FATAL_ERROR
            "Missing V1484 Full-VR transparent-fix contract: ${required_fragment}")
    endif()
endforeach()

message(STATUS "V1484 Full-VR transparent-fix admission contract verified")

