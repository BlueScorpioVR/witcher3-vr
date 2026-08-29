foreach(required_variable IN ITEMS
        DXGI_PROXY_SOURCE ROUTE_FLIGHT_HEADER ROUTE_FLIGHT_SOURCE)
    if(NOT DEFINED ${required_variable})
        message(FATAL_ERROR "${required_variable} is required")
    endif()
endforeach()

file(READ "${DXGI_PROXY_SOURCE}" dxgi_source)
file(READ "${ROUTE_FLIGHT_HEADER}" route_header)
file(READ "${ROUTE_FLIGHT_SOURCE}" route_source)
set(combined_source "${dxgi_source}\n${route_header}\n${route_source}")

set(required_fragments
    "[DIAG:SMOKE-SELECTOR-FLIGHT V1420]"
    "enum class RealSmokeSelectionReason"
    "RealSmokeSelectionReason::MissingCbvDescriptor"
    "RealSmokeSelectionReason::CameraMatchRejected"
    "RealSmokeSelectionReason::MissingRootTables"
    "record_real_smoke_selection("
    "EventCode::SmokeSelect"
    "case EventCode::SmokeSelect: return \"smoke_select\";"
    "route_flight_float_bits(trace.selected_distance)"
    "route_flight_float_bits(trace.separation_margin)"
    "final_variant <= 1 ? 1u : 2u"
    "prefer_closest_coherent_pair("
    "paired_camera_match_passes_guards("
    "paired_distance, eye, 0.0049f, 0.0005f"
    "smoke selector flight=cpu_pod_per_canonical_draw"
    "dump_last_seconds(\"V1442\", 15)"
    "V1421 smoke coherent_pair_selection=minimum_draw_b1_squared_distance"
    "V1422 smoke exact_eye_identity=selected_squared_distance_bit_exact_zero")

foreach(required_fragment IN LISTS required_fragments)
    string(FIND "${combined_source}" "${required_fragment}" fragment_index)
    if(fragment_index EQUAL -1)
        message(FATAL_ERROR
            "Missing V1422 smoke selector flight contract: ${required_fragment}")
    endif()
endforeach()

set(forbidden_fragments
    "D3D12_QUERY_HEAP_TYPE_PIPELINE_STATISTICS"
    "D3D12_QUERY_TYPE_PIPELINE_STATISTICS"
    "smoke_visibility_recorder"
    "g_smoke_visibility_query"
    "smoke_probe")

foreach(forbidden_fragment IN LISTS forbidden_fragments)
    string(FIND "${combined_source}" "${forbidden_fragment}" fragment_index)
    if(NOT fragment_index EQUAL -1)
        message(FATAL_ERROR
            "Forbidden active smoke diagnostic remains: ${forbidden_fragment}")
    endif()
endforeach()

message(STATUS "V1422 CPU-only smoke selector flight contract verified")
