if(NOT DEFINED DXGI_PROXY_SOURCE OR NOT EXISTS "${DXGI_PROXY_SOURCE}")
    message(FATAL_ERROR "dxgi_proxy.cpp was not provided")
endif()

file(READ "${DXGI_PROXY_SOURCE}" dxgi_proxy)

foreach(required_fragment IN ITEMS
        "build=V1511 base=V1509_witcher_sense_aligned_extent"
        "[FIX:STREAMLINE-RGBA8-COPY-FAMILY V1480 1/3]"
        "DXGI_FORMAT canonical_streamline_capture_format("
        "case DXGI_FORMAT_R8G8B8A8_TYPELESS:"
        "case DXGI_FORMAT_R8G8B8A8_UNORM:"
        "case DXGI_FORMAT_R8G8B8A8_UNORM_SRGB:"
        "return DXGI_FORMAT_R8G8B8A8_UNORM;"
        "g_streamline_capture_format == capture_format"
        "capture_desc.Format = capture_format;"
        "g_streamline_capture_format = capture_format;"
        "V1480 Streamline RGBA8 copy-family alias reused ring"
        "V1480 streamline_capture_format=canonical_rgba8_unorm")
    string(FIND "${dxgi_proxy}" "${required_fragment}" position)
    if(position EQUAL -1)
        message(FATAL_ERROR
            "Missing V1480 Streamline RGBA8 copy-family contract: ${required_fragment}")
    endif()
endforeach()

foreach(retired_fragment IN ITEMS
        "g_streamline_capture_format == source_desc.Format"
        "g_streamline_capture_format = source_desc.Format;")
    string(FIND "${dxgi_proxy}" "${retired_fragment}" position)
    if(NOT position EQUAL -1)
        message(FATAL_ERROR
            "Superseded format-identity ring recreation survived V1480: ${retired_fragment}")
    endif()
endforeach()

message(STATUS "V1480 Streamline RGBA8 copy-family stability verified")
