if(NOT DEFINED DXGI_PROXY_SOURCE)
    message(FATAL_ERROR "DXGI_PROXY_SOURCE is required")
endif()

file(READ "${DXGI_PROXY_SOURCE}" source)

set(required_fragments
    "[FIX:CROSS-QUEUE-RT-HISTORY-OWNERSHIP V1369 1/7]"
    "[FIX:CROSS-QUEUE-RT-HISTORY-OWNERSHIP V1369 2/7]"
    "[FIX:CROSS-QUEUE-RT-HISTORY-OWNERSHIP V1369 3/7]"
    "[FIX:CROSS-QUEUE-RT-HISTORY-OWNERSHIP V1369 4/7]"
    "[FIX:CROSS-QUEUE-RT-HISTORY-OWNERSHIP V1369 5/7]"
    "[FIX:CROSS-QUEUE-RT-HISTORY-OWNERSHIP V1369 6/7]"
    "[FIX:CROSS-QUEUE-RT-HISTORY-OWNERSHIP V1369 7/7]"
    "g_rt_ao_history_owners"
    "g_rt_shadow_history_owners"
    "g_rt_specular_history_owners"
    "track_rt_private_history_use("
    "order_rt_private_history_submission("
    "publish_rt_private_history_submissions("
    "consumer_queue->Wait("
    "build=V1443"
    "dump_last_seconds(\"V1443\", 15)")

foreach(required_fragment IN LISTS required_fragments)
    string(FIND "${source}" "${required_fragment}" fragment_index)
    if(fragment_index EQUAL -1)
        message(FATAL_ERROR
            "Missing V1369 RT-history ownership contract: ${required_fragment}")
    endif()
endforeach()

set(forbidden_fragments
    "g_rt_ao_history_pairs[eye][current_history_slot] = pair_id"
    "g_rt_shadow_history_pairs[eye][current_history_slot] = pair_id"
    "[completed_history_slot] = g_rt_specular_last_pair")

foreach(forbidden_fragment IN LISTS forbidden_fragments)
    string(FIND "${source}" "${forbidden_fragment}" fragment_index)
    if(NOT fragment_index EQUAL -1)
        message(FATAL_ERROR
            "Recording-time RT pair publication remains: ${forbidden_fragment}")
    endif()
endforeach()

message(STATUS "V1369 cross-queue RT history ownership contract verified")
