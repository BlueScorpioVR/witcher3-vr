if(NOT DEFINED DXGI_PROXY_SOURCE)
    message(FATAL_ERROR "DXGI_PROXY_SOURCE is required")
endif()

file(READ "${DXGI_PROXY_SOURCE}" source)

set(required_fragments
    "constexpr size_t kWitcherSenseDescriptorSetCount = 1u << 14;"
    "constexpr size_t kWitcherSenseDescriptorWays = 6;"
    "constexpr size_t kWitcherSenseHistoryWays = 2;"
    "constexpr size_t kWitcherSenseSignatureWays ="
    "std::atomic_flag writer = ATOMIC_FLAG_INIT;"
    "uint32_t next_history_victim{};"
    "uint32_t next_signature_victim{};"
    "g_witcher_sense_descriptor_cache"
    "classify_witcher_sense_descriptor("
    "store_witcher_sense_descriptor_target("
    "invalidate_witcher_sense_descriptor_target("
    "load_witcher_sense_descriptor_target("
    "WitcherSenseDescriptorKind expected_kind ="
    "? kWitcherSenseDescriptorWays : kWitcherSenseSignatureWays);"
    "copy_witcher_sense_descriptor_target("
    "const size_t first_way = history ? 0 : kWitcherSenseHistoryWays;"
    "selected = first_way + next_victim++ % way_count;"
    "copy_witcher_sense_descriptor_target(dest_cpu, src_cpu);"
    "const bool cbv_metadata = taau_metadata_hooks_needed() ||\n        real_smoke_world_up_binding_route_active() ||"
    "const bool legacy_resource_metadata = taau_metadata_hooks_needed() ||\n        rt_symmetric_dlss_per_eye_ao_history_active();"
    "descriptor_cache=1024x4_recyclable"
    "generic_cbv_mirror=off generic_reverse_mutex=off")

foreach(required_fragment IN LISTS required_fragments)
    string(FIND "${source}" "${required_fragment}" found)
    if(found EQUAL -1)
        message(FATAL_ERROR
            "Missing V1501 Witcher Senses hot-path contract: ${required_fragment}")
    endif()
endforeach()

foreach(marker_index RANGE 1 5)
    string(FIND "${source}"
        "[PERF:WITCHER-SENSE-BOUNDED-DESCRIPTORS V1499 ${marker_index}/5]"
        marker_found)
    if(marker_found EQUAL -1)
        message(FATAL_ERROR
            "Missing V1499 bounded-descriptor marker ${marker_index}/5")
    endif()
endforeach()

foreach(retired_fragment
    "kWitcherSenseDescriptorSlotCount"
    "kWitcherSenseDescriptorProbeCount"
    "kWitcherSenseDescriptorClaimed"
    "struct WitcherSenseSrvInfo"
    "resolve_witcher_sense_live_srv("
    "acquire_witcher_sense_live_history_rtv("
    "witcher_sense_live_resource_candidate"
    "[FIX:WITCHER-SENSE-RELEASE-DESCRIPTOR-AUTHORITY V1478"
    "V1478 witcher_sense_descriptor_authority=")
    string(FIND "${source}" "${retired_fragment}" retired_found)
    if(NOT retired_found EQUAL -1)
        message(FATAL_ERROR
            "Superseded Witcher descriptor path survived V1499: ${retired_fragment}")
    endif()
endforeach()

string(FIND "${source}"
    "bool resolve_witcher_sense_descriptor_target(" resolver_begin)
string(FIND "${source}"
    "struct WitcherSenseHistorySuppressionDrawScope" resolver_end)
if(resolver_begin EQUAL -1 OR resolver_end EQUAL -1 OR
   resolver_end LESS_EQUAL resolver_begin)
    message(FATAL_ERROR "Cannot isolate V1499 Witcher target resolver")
endif()
math(EXPR resolver_length "${resolver_end} - ${resolver_begin}")
string(SUBSTRING "${source}" ${resolver_begin} ${resolver_length} resolver_block)
foreach(forbidden_resolver_fragment
    "g_resource_descriptors"
    "load_resource_descriptor_fast("
    "g_reverse_mutex"
    "GetDesc()")
    string(FIND "${resolver_block}"
        "${forbidden_resolver_fragment}" forbidden_found)
    if(NOT forbidden_found EQUAL -1)
        message(FATAL_ERROR
            "Generic descriptor fallback survived in V1499 resolver: ${forbidden_resolver_fragment}")
    endif()
endforeach()

message(STATUS "V1501 Witcher Senses bounded descriptor hot path verified")

