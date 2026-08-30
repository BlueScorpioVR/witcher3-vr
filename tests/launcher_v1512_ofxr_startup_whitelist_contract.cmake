foreach(required_input STARTUP_CHECKS_SOURCE STARTUP_CHECKS_TEST_SOURCE)
    if(NOT DEFINED ${required_input})
        message(FATAL_ERROR "Missing V1512 launcher input: ${required_input}")
    endif()
endforeach()

file(READ "${STARTUP_CHECKS_SOURCE}" startup_source)
file(READ "${STARTUP_CHECKS_TEST_SOURCE}" startup_tests)

set(required_source_fragments
    "[FIX:OFXR-STARTUP-WHITELIST V1512 1/2]"
    "L\"XR_APILAYER_XRFrameBridge_diagnostic.dll\"")
foreach(required_fragment IN LISTS required_source_fragments)
    string(FIND "${startup_source}" "${required_fragment}" found)
    if(found EQUAL -1)
        message(FATAL_ERROR
            "Missing V1512 OFXR startup whitelist source: ${required_fragment}")
    endif()
endforeach()

set(required_test_fragments
    "[FIX:OFXR-STARTUP-WHITELIST V1512 2/2]"
    "Touch(root / L\"XR_APILAYER_XRFrameBridge_diagnostic.dll\")"
    "w3vr::IsKnownDx12Dll("
    "L\"xr_apilayer_xrframebridge_DIAGNOSTIC.DLL\""
    "Require(!w3vr::IsKnownDx12Dll(L\"version.dll\")")
foreach(required_fragment IN LISTS required_test_fragments)
    string(FIND "${startup_tests}" "${required_fragment}" found)
    if(found EQUAL -1)
        message(FATAL_ERROR
            "Missing V1512 OFXR startup whitelist regression: ${required_fragment}")
    endif()
endforeach()

message(STATUS "V1512 exact OFXR startup whitelist contract verified")
