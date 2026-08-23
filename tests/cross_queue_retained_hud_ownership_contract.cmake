if(NOT DEFINED DXGI_PROXY_SOURCE OR NOT EXISTS "${DXGI_PROXY_SOURCE}")
    message(FATAL_ERROR "dxgi_proxy.cpp was not provided")
endif()

file(READ "${DXGI_PROXY_SOURCE}" dxgi_proxy)

foreach(required_fragment IN ITEMS
        "[FIX:CROSS-QUEUE-RETAINED-HUD-OWNERSHIP V1366 1/6]"
        "publish_mode3_submissions_after_execute("
        "deferred_cross_queue_hud_publication"
        "[FIX:CROSS-QUEUE-RETAINED-HUD-OWNERSHIP V1366 2/6]"
        "cross_queue_publication &&"
        "producer_queue_fence_value == 0"
        "[FIX:CROSS-QUEUE-RETAINED-HUD-OWNERSHIP V1366 3/6]"
        "slot.tag_producer_queue_fence = tag_producer_queue_fence;"
        "[FIX:CROSS-QUEUE-RETAINED-HUD-OWNERSHIP V1366 4/6]"
        "g_command_queue->Wait(producer_fence, producer_value)"
        "[FIX:CROSS-QUEUE-RETAINED-HUD-OWNERSHIP V1366 5/6]"
        "candidate_ordered_for_present"
        "capture_ordered_for_present"
        "[FIX:CROSS-QUEUE-RETAINED-HUD-OWNERSHIP V1366 6/6]"
        "V1366 retained_hud_ownership=exact_ordered_submission"
        "dump_last_seconds(\"V1409\", 15)")
    string(FIND "${dxgi_proxy}" "${required_fragment}" position)
    if(position EQUAL -1)
        message(FATAL_ERROR
            "Missing V1366 cross-queue retained-HUD contract: ${required_fragment}")
    endif()
endforeach()

foreach(forbidden_fragment IN ITEMS
        "publish_puredark_afw_submissions_after_execute("
        "capture_owns_tag_timeline")
    string(FIND "${dxgi_proxy}" "${forbidden_fragment}" position)
    if(NOT position EQUAL -1)
        message(FATAL_ERROR
            "Superseded same-timeline HUD path remains: ${forbidden_fragment}")
    endif()
endforeach()

message(STATUS "V1366 cross-queue retained-HUD ownership contract verified")
