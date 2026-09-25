if(NOT DEFINED DXGI_PROXY_SOURCE)
    message(FATAL_ERROR "DXGI_PROXY_SOURCE is required")
endif()

file(READ "${DXGI_PROXY_SOURCE}" source)

foreach(required_fragment IN ITEMS
        "ID3D12Fence* last_use_fence{};"
        "uint64_t last_use_fence_value{};"
        "!private_resource_slot_retired("
        "slot.last_use_fence_value = UINT64_MAX;"
        "finish_mode3_early_hud_consumer("
        "slot.last_use_fence_value = submitted ? fence_value : 0;"
        "V1538 retained_hud_snapshot_lifetime=xr_consumer_fence"
        "aer_afw=1 strict_stereo=1 logging_timing_independent=1")
    string(FIND "${source}" "${required_fragment}" fragment_position)
    if(fragment_position EQUAL -1)
        message(FATAL_ERROR
            "Missing V1538 retained-HUD consumer retirement contract: ${required_fragment}")
    endif()
endforeach()

foreach(forbidden_fragment IN ITEMS
        "kMode3EarlyHudSlotCount = 7"
        "kMode3EarlyHudSlotCount = 8"
        "Sleep("
        "WaitForSingleObject(g_xr_fence_event, INFINITE)")
    string(FIND "${source}" "${forbidden_fragment}" fragment_position)
    if(NOT fragment_position EQUAL -1)
        message(FATAL_ERROR
            "Forbidden V1538 HUD lifetime workaround remains: ${forbidden_fragment}")
    endif()
endforeach()
