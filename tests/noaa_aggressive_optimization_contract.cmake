if(NOT DEFINED DXGI_PROXY_SOURCE OR NOT EXISTS "${DXGI_PROXY_SOURCE}")
    message(FATAL_ERROR "DXGI proxy source was not provided")
endif()

file(READ "${DXGI_PROXY_SOURCE}" source)

set(required_fragments
    "build=V1511 base=V1509_witcher_sense_aligned_extent"
    "PERF:NOAA-TILED-TLS V1442"
    "return asymmetric_tiled_culling_fix_needed() ||"
    "snapshot.compute_tables = state->compute_tables"
    "state->compute_tables[root_parameter_index] = base_descriptor"
    "if (slot.state.recording_epoch != recording_epoch)"
    "slot.recording_epoch_source->load("
    "slot.state.recording_epoch = recording_epoch"
    "advance_command_list_recording_epoch(command_list)"
    "PERF:NOAA-NONINDEXED-FAST-PATH V1442"
    "if (clean_strict_noaa && !functional_aim_candidate &&")

foreach(fragment IN LISTS required_fragments)
    string(FIND "${source}" "${fragment}" position)
    if(position EQUAL -1)
        message(FATAL_ERROR "Missing V1442 No-AA aggressive contract: ${fragment}")
    endif()
endforeach()

message(STATUS "V1442 No-AA aggressive optimization contract verified")
