if(NOT DEFINED DXGI_PROXY_SOURCE OR NOT EXISTS "${DXGI_PROXY_SOURCE}")
    message(FATAL_ERROR "dxgi_proxy.cpp was not provided")
endif()

file(READ "${DXGI_PROXY_SOURCE}" source)

foreach(required_fragment IN ITEMS
        "build=V1511 base=V1509_witcher_sense_aligned_extent"
        "[FIX:AER-FULL-VR-SCENE-ONLY-ADMISSION V1509 1/3]"
        "[FIX:AER-FULL-VR-SCENE-ONLY-ADMISSION V1509 2/3]"
        "[FIX:AER-FULL-VR-SCENE-ONLY-ADMISSION V1509 3/3]"
        "const bool aer_full_vr_retained_hud_route ="
        "aer_full_vr_scene_only_admission_ready("
        "sequential_cinema_pair_available(),"
        "mode3_early_hud_pair_ready());"
        "aer_full_vr_retained_hud_route ||"
        "aer_full_vr_scene_only_ready &&"
        "V1509 aer_full_vr_scene_only=sequential_cinema_pair_plus_retained_hud_pair"
        "backends=noaa_taau_dlss"
        "dump_last_seconds(\"V1511\", 15)")
    string(FIND "${source}" "${required_fragment}" fragment_position)
    if(fragment_position EQUAL -1)
        message(FATAL_ERROR
            "Missing V1509 AER Full-VR scene-only admission: ${required_fragment}")
    endif()
endforeach()

message(STATUS "V1509 AER Full-VR scene-only admission verified")
