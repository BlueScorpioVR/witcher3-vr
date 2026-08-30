foreach(required_input IN ITEMS
        LAUNCHER_CONFIG_SOURCE
        LAUNCHER_MAIN_SOURCE
        OFXR_ENV_SOURCE
        OFXR_ENV_HEADER
        LAUNCHER_TEST_SOURCE)
    if(NOT DEFINED ${required_input} OR NOT EXISTS "${${required_input}}")
        message(FATAL_ERROR "Missing V1510 launcher input: ${required_input}")
    endif()
endforeach()

file(READ "${LAUNCHER_CONFIG_SOURCE}" launcher_config)
file(READ "${LAUNCHER_MAIN_SOURCE}" launcher_main)
file(READ "${OFXR_ENV_SOURCE}" ofxr_source)
file(READ "${OFXR_ENV_HEADER}" ofxr_header)
file(READ "${LAUNCHER_TEST_SOURCE}" launcher_tests)

foreach(required_fragment IN ITEMS
        "[FIX:OFXR-ROOT-LAYOUT V1510 1/3]"
        "const auto layer_directory = launcher_directory;"
        "L\"XR_APILAYER_XRFrameBridge_diagnostic.dll\""
        "L\"XR_APILAYER_XRFrameBridge_diagnostic.json\""
        "L\"ofxr_bridge.ini\""
        "L\"XR_API_LAYER_PATH=\" + layer_directory.wstring()"
        "XRFG-V040 reads [ofxr] backend from the root ofxr_bridge.ini")
    string(FIND "${ofxr_source}" "${required_fragment}" fragment_position)
    if(fragment_position EQUAL -1)
        message(FATAL_ERROR
            "Missing V1510 OFXR root-layout contract: ${required_fragment}")
    endif()
endforeach()

foreach(required_fragment IN ITEMS
        "[FIX:OFXR-ROOT-LAYOUT V1510 2/3]"
        "launcher_directory / L\"ofxr\""
        "launcher_directory / L\"OFXRBridgeTray.exe\""
        "std::filesystem::remove_all(legacy_directory"
        "std::filesystem::remove(legacy_tray")
    string(FIND "${ofxr_source}" "${required_fragment}" fragment_position)
    if(fragment_position EQUAL -1)
        message(FATAL_ERROR
            "Missing V1510 retired-payload cleanup contract: ${required_fragment}")
    endif()
endforeach()

foreach(required_fragment IN ITEMS
        "[FIX:OFXR-ROOT-LAYOUT V1510 3/3]"
        "w3vr::RemoveRetiredOfxrPayload("
        "g_app.paths.launcher_directory, ofxr_cleanup_error")
    string(FIND "${launcher_main}" "${required_fragment}" fragment_position)
    if(fragment_position EQUAL -1)
        message(FATAL_ERROR
            "Missing V1510 startup cleanup call: ${required_fragment}")
    endif()
endforeach()

string(FIND "${ofxr_header}"
    "bool RemoveRetiredOfxrPayload(" cleanup_declaration_position)
if(cleanup_declaration_position EQUAL -1)
    message(FATAL_ERROR "Missing V1510 cleanup API declaration")
endif()

foreach(required_fragment IN ITEMS
        "directory / L\"ofxr_bridge.ini\""
        "IniDocument::Load(paths.ofxr_bridge_ini, error)"
        "AtomicWriteWithBackup(paths.ofxr_bridge_ini")
    string(FIND "${launcher_config}" "${required_fragment}" fragment_position)
    if(fragment_position EQUAL -1)
        message(FATAL_ERROR
            "Missing V1510 root INI ownership contract: ${required_fragment}")
    endif()
endforeach()

foreach(required_fragment IN ITEMS
        "Write(launcher / \"XR_APILAYER_XRFrameBridge_diagnostic.dll\""
        "Write(launcher / \"XR_APILAYER_XRFrameBridge_diagnostic.json\""
        "Write(launcher / \"ofxr_bridge.ini\""
        "!fs::exists(launcher / \"ofxr\")"
        "!fs::exists(launcher / \"OFXRBridgeTray.exe\")"
        "CountEnvironmentVariable(entries, L\"XRFG_FLOW_BACKEND\") == 0")
    string(FIND "${launcher_tests}" "${required_fragment}" fragment_position)
    if(fragment_position EQUAL -1)
        message(FATAL_ERROR
            "Missing V1510 launcher regression coverage: ${required_fragment}")
    endif()
endforeach()

foreach(retired_fragment IN ITEMS
        "const auto layer_directory = launcher_directory / L\"ofxr\""
        "Install the V012 bridge package in the ofxr folder"
        "? L\"XRFG_FLOW_BACKEND=nvidia\""
        ": L\"XRFG_FLOW_BACKEND=fidelityfx\"")
    string(FIND "${ofxr_source}" "${retired_fragment}" retired_position)
    if(NOT retired_position EQUAL -1)
        message(FATAL_ERROR
            "Retired OFXR subfolder/backend override survived V1510: ${retired_fragment}")
    endif()
endforeach()

message(STATUS "V1510 root-owned OFXR layout contract verified")
