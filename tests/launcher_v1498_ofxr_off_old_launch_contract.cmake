foreach(required_input IN ITEMS
        LAUNCHER_MAIN
        LAUNCHER_CONFIG_HEADER
        OFXR_ENV_SOURCE
        OFXR_ENV_HEADER
        LAUNCHER_CMAKE)
    if(NOT DEFINED ${required_input} OR
            NOT EXISTS "${${required_input}}")
        message(FATAL_ERROR "Missing V1498 launcher input: ${required_input}")
    endif()
endforeach()

file(READ "${LAUNCHER_MAIN}" launcher_main)
file(READ "${LAUNCHER_CONFIG_HEADER}" launcher_config_header)
file(READ "${OFXR_ENV_SOURCE}" ofxr_source)
file(READ "${OFXR_ENV_HEADER}" ofxr_header)
file(READ "${LAUNCHER_CMAKE}" launcher_cmake)

foreach(required_fragment IN ITEMS
        "[FIX:OFXR-OFF-OLD-LAUNCH V1498 2/2]"
        "if (backend == FrameGenerationBackend::Off) {"
        "nullptr, nullptr, FALSE, 0, nullptr,"
        "BuildEnabledOfxrLaunchEnvironment("
        "FALSE, CREATE_UNICODE_ENVIRONMENT,"
        "environment.data(), g_app.paths.launcher_directory.c_str()")
    string(FIND "${launcher_main}" "${required_fragment}" fragment_position)
    if(fragment_position EQUAL -1)
        message(FATAL_ERROR
            "Missing V1498 physical OFXR-Off launch contract: ${required_fragment}")
    endif()
endforeach()

string(FIND "${launcher_main}"
    "if (backend == FrameGenerationBackend::Off) {" off_branch_position)
string(FIND "${launcher_main}"
    "BuildEnabledOfxrLaunchEnvironment(" ofxr_builder_position)
if(off_branch_position GREATER ofxr_builder_position)
    message(FATAL_ERROR
        "V1498 OFXR builder is reachable before the physical Off branch")
endif()

foreach(required_fragment IN ITEMS
        "[FIX:OFXR-OFF-OLD-LAUNCH V1498 1/2]"
        "bool BuildEnabledOfxrLaunchEnvironment("
        "if (backend == FrameGenerationBackend::Off) {"
        "OFXR launch environment requested while Frame Generation is Off.")
    string(FIND "${ofxr_source}" "${required_fragment}" fragment_position)
    if(fragment_position EQUAL -1)
        message(FATAL_ERROR
            "Missing V1498 enabled-only OFXR builder contract: ${required_fragment}")
    endif()
endforeach()

foreach(required_fragment IN ITEMS
        "bool BuildEnabledOfxrLaunchEnvironment("
        "FrameGenerationBackend frame_generation_backend{\n        FrameGenerationBackend::Off};"
        "ofxr_launch_environment.cpp")
    if(required_fragment STREQUAL "FrameGenerationBackend frame_generation_backend{\n        FrameGenerationBackend::Off};")
        set(fragment_source "${launcher_config_header}")
    elseif(required_fragment STREQUAL "ofxr_launch_environment.cpp")
        set(fragment_source "${launcher_cmake}")
    else()
        set(fragment_source "${ofxr_header}")
    endif()
    string(FIND "${fragment_source}" "${required_fragment}" fragment_position)
    if(fragment_position EQUAL -1)
        message(FATAL_ERROR
            "Missing V1498 launcher integration/default contract: ${required_fragment}")
    endif()
endforeach()

foreach(retired_fragment IN ITEMS
        "BuildOfxrLaunchEnvironment("
        "use_ofxr ? CREATE_UNICODE_ENVIRONMENT : 0"
        "use_ofxr ? environment.data() : nullptr")
    string(FIND "${launcher_main}${ofxr_source}${ofxr_header}"
        "${retired_fragment}" retired_position)
    if(NOT retired_position EQUAL -1)
        message(FATAL_ERROR
            "Retired conditional OFXR launch path survived V1498: ${retired_fragment}")
    endif()
endforeach()

message(STATUS "V1498 physical OFXR-Off old-launch contract verified")
