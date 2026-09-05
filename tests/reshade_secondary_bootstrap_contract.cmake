if(NOT DEFINED DXGI_PROXY_SOURCE OR
        NOT EXISTS "${DXGI_PROXY_SOURCE}")
    message(FATAL_ERROR "DXGI_PROXY_SOURCE was not provided")
endif()

file(READ "${DXGI_PROXY_SOURCE}" renderer)

foreach(required IN ITEMS
        "[TRIAL:RESHADE-SECONDARY-BOOTSTRAP V23000 1/4]"
        "[TRIAL:RESHADE-SECONDARY-BOOTSTRAP V23000 2/4]"
        "[TRIAL:RESHADE-SECONDARY-BOOTSTRAP V23000 3/4]"
        "[TRIAL:RESHADE-SECONDARY-BOOTSTRAP V23000 4/4]"
        "_wcsicmp(filename, L\"witcher3.exe\") == 0"
        "L\"ReShade64.dll\""
        "L\"ReShade.ini\""
        "hook_factory(bootstrap_factory);"
        "initialize_real_d3d12_create_device_export();"
        "LoadLibraryExW("
        "GetProcAddress(module, \"ReShadeVersion\")"
        "secondary_reshade_dxgi_proc(\"CreateDXGIFactory2\")"
        "const bool reshade_outer = prepare_secondary_reshade_runtime();"
        "!reentry && !reshade_outer"
        "order=reshade_present_then_w3vr_openxr")
    string(FIND "${renderer}" "${required}" found)
    if(found EQUAL -1)
        message(FATAL_ERROR
            "Missing V23000 ReShade secondary bootstrap contract: ${required}")
    endif()
endforeach()

string(FIND "${renderer}"
    "hook_factory(bootstrap_factory);" bootstrap_hook)
string(FIND "${renderer}"
    "HMODULE module = LoadLibraryExW(" reshade_load)
if(bootstrap_hook EQUAL -1 OR reshade_load EQUAL -1 OR
        NOT bootstrap_hook LESS reshade_load)
    message(FATAL_ERROR
        "V23000 must hook the raw factory before loading ReShade")
endif()

foreach(forbidden IN ITEMS
        "ProxyLibrary=witcher3vr_dxgi.dll"
        "LoadLibraryW(L\"dxgi.dll\")")
    string(FIND "${renderer}" "${forbidden}" found)
    if(NOT found EQUAL -1)
        message(FATAL_ERROR
            "Forbidden V23000 proxy-chain path remains: ${forbidden}")
    endif()
endforeach()
