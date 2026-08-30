if(NOT DEFINED DXGI_PROXY_SOURCE OR NOT EXISTS "${DXGI_PROXY_SOURCE}")
    message(FATAL_ERROR "DXGI proxy source is required")
endif()

file(READ "${DXGI_PROXY_SOURCE}" source)

foreach(required_fragment IN ITEMS
        "build=V1501 base=V1499_witcher_sense_expanded_partition_cache"
        "[FIX:MANUAL-CINEMA-SINGLE-RECENTER V1497 1/3]"
        "[FIX:MANUAL-CINEMA-SINGLE-RECENTER V1497 2/3]"
        "[FIX:MANUAL-CINEMA-SINGLE-RECENTER V1497 3/3]"
        "if (!g_force_mono_cinema.load(std::memory_order_relaxed)) {\n                g_auto_recenter_on_packed_lock_armed.store("
        "if (forced) {\n            g_engine_hmd_forward_valid.store(false, std::memory_order_release);"
        "g_taau_last_submitted_pair[0].load(std::memory_order_acquire) !=\n                left.pair_id"
        "g_taau_last_submitted_pair[1].load(std::memory_order_acquire) !=\n                left.pair_id"
        "V1497 manual_cinema_recenter=single_f10_owner"
        "taau_submitted_pair_gate=unchanged"
        "dump_last_seconds(\"V1501\", 15)")
    string(FIND "${source}" "${required_fragment}" fragment_position)
    if(fragment_position EQUAL -1)
        message(FATAL_ERROR
            "Missing V1497 manual-Cinema single-recenter contract: ${required_fragment}")
    endif()
endforeach()

set(retired_detector_arm
    "if (cinema_mode) {\n            g_auto_recenter_on_packed_lock_armed.store(")
string(FIND "${source}" "${retired_detector_arm}" retired_detector_arm_position)
if(NOT retired_detector_arm_position EQUAL -1)
    message(FATAL_ERROR
        "The unconditional Cinema detector recenter arm survived V1497")
endif()

message(STATUS "V1497 manual-Cinema single-recenter contract verified")
