if(NOT DEFINED DXGI_PROXY_SOURCE)
    message(FATAL_ERROR "DXGI_PROXY_SOURCE is required")
endif()

file(READ "${DXGI_PROXY_SOURCE}" source)

set(required_fragments
    "build=V1509 base=V1508_aer_full_vr_scene_only_admission"
    "constexpr size_t kWitcherSenseDescriptorSetCount = 1u << 14;"
    "constexpr size_t kWitcherSenseDescriptorWays = 6;"
    "constexpr size_t kWitcherSenseHistoryWays = 2;"
    "kWitcherSenseDescriptorWays - kWitcherSenseHistoryWays;"
    "uint32_t next_history_victim{};"
    "uint32_t next_signature_victim{};"
    "const size_t first_way = history ? 0 : kWitcherSenseHistoryWays;"
    "? set.next_history_victim : set.next_signature_victim;"
    "WitcherSenseDescriptorKind expected_kind ="
    "expected_kind == WitcherSenseDescriptorKind::History;"
    "? kWitcherSenseHistoryWays"
    "? kWitcherSenseDescriptorWays : kWitcherSenseSignatureWays);"
    "WitcherSenseDescriptorKind::Scene, t0"
    "WitcherSenseDescriptorKind::History, t2"
    "WitcherSenseDescriptorKind::Auxiliary, t3"
    "descriptor_cache=16384_sets_x6 history_ways=2 signature_ways=4"
    "cached_history_probe=2 recyclable=1"
    "diagnostic_logging_required=0 base=V1499")

foreach(required_fragment IN LISTS required_fragments)
    string(FIND "${source}" "${required_fragment}" found)
    if(found EQUAL -1)
        message(FATAL_ERROR
            "Missing V1501 expanded-partition contract: ${required_fragment}")
    endif()
endforeach()

foreach(marker_index RANGE 1 3)
    string(FIND "${source}"
        "[PERF:WITCHER-SENSE-EXPANDED-PARTITION-CACHE V1501 ${marker_index}/3]"
        marker_found)
    if(marker_found EQUAL -1)
        message(FATAL_ERROR
            "Missing V1501 expanded-partition marker ${marker_index}/3")
    endif()
endforeach()

foreach(retired_fragment
    "constexpr size_t kWitcherSenseDescriptorSetCount = 1u << 10;"
    "constexpr size_t kWitcherSenseDescriptorWays = 4;"
    "[PERF:WITCHER-SENSE-HISTORY-RESERVED-WAYS V1500"
    "V1500 witcher_sense_descriptor_cache=1024_sets_x4")
    string(FIND "${source}" "${retired_fragment}" retired_found)
    if(NOT retired_found EQUAL -1)
        message(FATAL_ERROR
            "Superseded V1500 cache survived V1501: ${retired_fragment}")
    endif()
endforeach()

message(STATUS "V1501 Witcher Senses expanded partition cache verified")

