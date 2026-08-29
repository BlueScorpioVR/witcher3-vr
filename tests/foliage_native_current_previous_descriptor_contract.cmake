if(NOT DEFINED DXGI_PROXY_SOURCE OR NOT EXISTS "${DXGI_PROXY_SOURCE}")
    message(FATAL_ERROR "dxgi_proxy.cpp was not provided")
endif()
if(NOT DEFINED LIFETIME_EVIDENCE OR NOT EXISTS "${LIFETIME_EVIDENCE}")
    message(FATAL_ERROR "Native table lifetime evidence was not provided")
endif()

file(READ "${DXGI_PROXY_SOURCE}" dxgi_proxy)
file(READ "${LIFETIME_EVIDENCE}" lifetime_evidence)

foreach(fragment IN ITEMS
        "bool prepare_foliage_hmd_base_draw("
        "native_b0_descriptor"
        "native_b12_descriptor"
        "g_create_cbv("
        "private_b0_desc, native_b0_descriptor"
        "private_b12_desc, native_b12_descriptor"
        "store_cbv_descriptor("
        "compensate_b0_orientation("
        "compensate_b12_orientation("
        "resolve_foliage_hmd_base_previous_camera("
        "slot.retirement_fence = private_resource_ordered"
        "slot.retirement_fence_value = private_resource_ordered"
        "private_resource_slot_retired("
        "descriptor_copies=0 heap_switches=0 root_rebinds=0")
    string(FIND "${dxgi_proxy}" "${fragment}" position)
    if(position EQUAL -1)
        message(FATAL_ERROR
            "Missing native current/previous foliage contract: ${fragment}")
    endif()
endforeach()

foreach(fragment IN ITEMS
        "g_foliage_bound_basis_override_heap"
        "kFoliageBoundBasisDescriptorBlockSize"
        "FoliageBoundBasisDrawOverride"
        "begin_foliage_bound_basis_draw("
        "end_foliage_bound_basis_draw("
        "g_taau_slot_fence")
    string(FIND "${dxgi_proxy}" "${fragment}" position)
    if(NOT position EQUAL -1)
        message(FATAL_ERROR
            "Superseded private-table foliage path remains: ${fragment}")
    endif()
endforeach()

foreach(fragment IN ITEMS
        "\"target_draws\": 119"
        "\"unique_target_root3_allocations\": 119"
        "\"same_root3_immediate_neighbor_count\": 0"
        "\"neighbor_radius\": 2")
    string(FIND "${lifetime_evidence}" "${fragment}" position)
    if(position EQUAL -1)
        message(FATAL_ERROR
            "Missing native table lifetime proof: ${fragment}")
    endif()
endforeach()

message(STATUS "Foliage native current/previous descriptor contract verified")
