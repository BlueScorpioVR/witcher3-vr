if(NOT DEFINED DXGI_PROXY_SOURCE OR NOT EXISTS "${DXGI_PROXY_SOURCE}")
    message(FATAL_ERROR "dxgi_proxy.cpp was not provided")
endif()

file(READ "${DXGI_PROXY_SOURCE}" dxgi_proxy)

set(required_fragments
    "if (taau_stereo_route_active())"
    "decide_cb10_producer_identity("
    "matrix_identity.matched_eye"
    "matrix_identity.matched_pair_id"
    "matrix_identity.matched_generation"
    "current_capture_generation"
    "matrix_identity.matrix_error"
    "TAAU CB10 producer authority"
)
foreach(fragment IN LISTS required_fragments)
    string(FIND "${dxgi_proxy}" "${fragment}" position)
    if(position EQUAL -1)
        message(FATAL_ERROR
            "Missing strict-Stereo TAAU producer identity contract: ${fragment}")
    endif()
endforeach()

set(forbidden_fragments
    "expected_pair_id = history_floor"
    "TAAU completed-tag authority"
    "TAAU forward completed-tag eye authority"
    "forward_queue_eye_authority"
)
foreach(fragment IN LISTS forbidden_fragments)
    string(FIND "${dxgi_proxy}" "${fragment}" position)
    if(NOT position EQUAL -1)
        message(FATAL_ERROR
            "Superseded TAAU identity fallback remains: ${fragment}")
    endif()
endforeach()

message(STATUS "Strict-Stereo TAAU CB10 producer identity contract verified")
