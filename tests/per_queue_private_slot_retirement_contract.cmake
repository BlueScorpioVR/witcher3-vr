if(NOT DEFINED DXGI_PROXY_SOURCE)
    message(FATAL_ERROR "DXGI_PROXY_SOURCE is required")
endif()

file(READ "${DXGI_PROXY_SOURCE}" source)

set(required_fragments
    "[FIX:PER-QUEUE-PRIVATE-SLOT-RETIREMENT V1367 1/5]"
    "[FIX:PER-QUEUE-PRIVATE-SLOT-RETIREMENT V1367 2/5]"
    "[FIX:PER-QUEUE-PRIVATE-SLOT-RETIREMENT V1367 3/5]"
    "[FIX:PER-QUEUE-PRIVATE-SLOT-RETIREMENT V1367 4/5]"
    "[FIX:PER-QUEUE-PRIVATE-SLOT-RETIREMENT V1367 5/5]"
    "std::unordered_map<ID3D12CommandQueue*, PrivateResourceQueueTimeline>"
    "slot.retirement_fence = private_resource_ordered"
    "private_resource_slot_retired("
    "build=V1501"
    "dump_last_seconds(\"V1501\", 15)"
    "uint32_t slot_count{1}"
    "slot.retirement_fence = private_resource_ordered")

foreach(required_fragment IN LISTS required_fragments)
    string(FIND "${source}" "${required_fragment}" fragment_index)
    if(fragment_index EQUAL -1)
        message(FATAL_ERROR
            "Missing V1367 per-queue retirement contract: ${required_fragment}")
    endif()
endforeach()

set(forbidden_fragments
    "g_taau_slot_fence"
    "g_taau_slot_fence_value"
    "ensure_taau_slot_fence")

foreach(forbidden_fragment IN LISTS forbidden_fragments)
    string(FIND "${source}" "${forbidden_fragment}" fragment_index)
    if(NOT fragment_index EQUAL -1)
        message(FATAL_ERROR
            "Forbidden global retirement path remains: ${forbidden_fragment}")
    endif()
endforeach()

message(STATUS "V1367 per-queue private slot retirement contract verified")
