if(NOT DEFINED DXGI_PROXY_SOURCE OR NOT EXISTS "${DXGI_PROXY_SOURCE}")
    message(FATAL_ERROR "DXGI proxy source is required")
endif()

file(READ "${DXGI_PROXY_SOURCE}" source)

foreach(fragment IN ITEMS
        "std::atomic<bool> g_manual_cinema_f10_latched{};"
        "(GetAsyncKeyState(VK_F10) & 0x8000) != 0"
        "!g_manual_cinema_f10_latched.exchange(true, std::memory_order_relaxed)"
        "g_manual_cinema_f10_latched.store(false, std::memory_order_relaxed);"
        "if (f10_pressed) {"
        "g_force_mono_cinema.store(forced, std::memory_order_release);")
    string(FIND "${source}" "${fragment}" position)
    if(position EQUAL -1)
        message(FATAL_ERROR "Missing F10 physical key-edge contract: ${fragment}")
    endif()
endforeach()

string(FIND "${source}" "GetAsyncKeyState(VK_F10) & 1" obsolete)
if(NOT obsolete EQUAL -1)
    message(FATAL_ERROR "Unreliable F10 low-bit polling remains")
endif()

message(STATUS "F10 physical key-edge contract verified")
