if(NOT DEFINED DXGI_PROXY_SOURCE)
    message(FATAL_ERROR "DXGI_PROXY_SOURCE is required")
endif()

file(READ "${DXGI_PROXY_SOURCE}" source)

set(required_fragments
    "[FIX:CROSS-QUEUE-SCENE-CAPTURE-OWNERSHIP V1368 1/7]"
    "[FIX:CROSS-QUEUE-SCENE-CAPTURE-OWNERSHIP V1368 2/7]"
    "[FIX:CROSS-QUEUE-SCENE-CAPTURE-OWNERSHIP V1368 3/7]"
    "[FIX:CROSS-QUEUE-SCENE-CAPTURE-OWNERSHIP V1368 4/7]"
    "[FIX:CROSS-QUEUE-SCENE-CAPTURE-OWNERSHIP V1368 5/7]"
    "[FIX:CROSS-QUEUE-SCENE-CAPTURE-OWNERSHIP V1368 6/7]"
    "[FIX:CROSS-QUEUE-SCENE-CAPTURE-OWNERSHIP V1368 7/7]"
    "g_streamline_capture_pending_publications"
    "take_streamline_capture_submissions("
    "publish_streamline_capture_submissions("
    "g_command_queue->Wait("
    "candidate.last_use_fence"
    "g_packed_present_cache_last_use_fence"
    "build=V1410"
    "dump_last_seconds(\"V1410\", 15)")

foreach(required_fragment IN LISTS required_fragments)
    string(FIND "${source}" "${required_fragment}" fragment_index)
    if(fragment_index EQUAL -1)
        message(FATAL_ERROR
            "Missing V1368 scene-capture ownership contract: ${required_fragment}")
    endif()
endforeach()

set(forbidden_fragments
    "g_streamline_capture_latest_slot[output.eye].store(slot_index)"
    "mark_engine_pair_output_captured(output.pair_id, output.eye)")

foreach(forbidden_fragment IN LISTS forbidden_fragments)
    string(FIND "${source}" "${forbidden_fragment}" fragment_index)
    if(NOT fragment_index EQUAL -1)
        message(FATAL_ERROR
            "Recording-time scene publication remains: ${forbidden_fragment}")
    endif()
endforeach()

message(STATUS "V1368 cross-queue scene capture ownership contract verified")
