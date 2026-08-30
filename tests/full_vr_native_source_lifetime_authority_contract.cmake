if(NOT DEFINED DXGI_PROXY_SOURCE OR NOT EXISTS "${DXGI_PROXY_SOURCE}")
    message(FATAL_ERROR "dxgi_proxy.cpp was not provided")
endif()

file(READ "${DXGI_PROXY_SOURCE}" source)

foreach(required_fragment IN ITEMS
        "build=V1501 base=V1499_witcher_sense_expanded_partition_cache"
        "[FIX:FULL-VR-FACTORY-LIFETIME-AUTHORITY V1486 1/3]"
        "[FIX:FULL-VR-FACTORY-LIFETIME-AUTHORITY V1486 2/3]"
        "[FIX:FULL-VR-FACTORY-LIFETIME-AUTHORITY V1486 3/3]"
        "g_full_vr_factory_camera_last_present.load("
        "g_full_vr_native_reused_camera_last_present.load("
        "const bool native_factory_source ="
        "const bool native_reused_source ="
        "const bool native_source = native_factory_source || native_reused_source;"
        "g_full_vr_native_reused_camera_last_present.store("
        "authority=native_source_lifetime"
        "transparent_authority=separate_native_reused_lifetime"
        "dump_last_seconds(\"V1501\", 15)")
    string(FIND "${source}" "${required_fragment}" fragment_index)
    if(fragment_index EQUAL -1)
        message(FATAL_ERROR
            "Missing V1487 Full-VR native-source lifetime contract: ${required_fragment}")
    endif()
endforeach()

foreach(forbidden_fragment IN ITEMS
        "[FIX:FULL-VR-DEFERRED-TRANSPARENT-AUTHORITY V1485"
        "authority=streamline_deferred"
        "authority=factory_lifetime present=")
    string(FIND "${source}" "${forbidden_fragment}" fragment_index)
    if(NOT fragment_index EQUAL -1)
        message(FATAL_ERROR
            "Superseded Full-VR transparent authority survived: ${forbidden_fragment}")
    endif()
endforeach()

message(STATUS "V1487 Full-VR native-source lifetime authority contract verified")
