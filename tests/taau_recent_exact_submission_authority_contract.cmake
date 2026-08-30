if(NOT DEFINED DXGI_PROXY_SOURCE OR NOT EXISTS "${DXGI_PROXY_SOURCE}")
    message(FATAL_ERROR "DXGI proxy source is required")
endif()

file(READ "${DXGI_PROXY_SOURCE}" source)

foreach(required_fragment IN ITEMS
        "build=V1511 base=V1509_witcher_sense_aligned_extent"
        "[FIX:TAAU-RECENT-EXACT-SUBMISSION-AUTHORITY V1503 1/4]"
        "[FIX:TAAU-RECENT-EXACT-SUBMISSION-AUTHORITY V1503 2/4]"
        "[FIX:TAAU-RECENT-EXACT-SUBMISSION-AUTHORITY V1503 3/4]"
        "[FIX:TAAU-RECENT-EXACT-SUBMISSION-AUTHORITY V1503 4/4]"
        "g_taau_previous_forward_submitted_pair"
        "recent_exact_submission_matches("
        "strict_stereo_only=1"
        "manual_cinema_recenter=pre_V1497_detector_owner"
        "dump_last_seconds(\"V1511\", 15)")
    string(FIND "${source}" "${required_fragment}" fragment_position)
    if(fragment_position EQUAL -1)
        message(FATAL_ERROR
            "Missing V1503 recent exact-submission contract: ${required_fragment}")
    endif()
endforeach()

foreach(retired_fragment IN ITEMS
        "[FIX:MANUAL-CINEMA-SINGLE-RECENTER V1497"
        "V1497 manual_cinema_recenter=single_f10_owner"
        "if (!g_force_mono_cinema.load(std::memory_order_relaxed)) {\n                g_auto_recenter_on_packed_lock_armed.store(")
    string(FIND "${source}" "${retired_fragment}" retired_position)
    if(NOT retired_position EQUAL -1)
        message(FATAL_ERROR
            "Rejected V1497 Cinema path survived V1503: ${retired_fragment}")
    endif()
endforeach()

set(detector_arm
    "if (cinema_mode) {\n            g_auto_recenter_on_packed_lock_armed.store(")
string(FIND "${source}" "${detector_arm}" detector_arm_position)
if(detector_arm_position EQUAL -1)
    message(FATAL_ERROR "Pre-V1497 Cinema detector recenter owner was not restored")
endif()

message(STATUS "V1503 recent exact-submission authority contract verified")
