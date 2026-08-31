if(NOT DEFINED LAUNCHER_MAIN_SOURCE OR
        NOT EXISTS "${LAUNCHER_MAIN_SOURCE}")
    message(FATAL_ERROR "launcher/main.cpp was not provided")
endif()

file(READ "${LAUNCHER_MAIN_SOURCE}" source)

foreach(required IN ITEMS
        "L\"Alt. resize\""
        "Required for Presentation Size to work correctly with SteamVR."
        "Image quality is slightly reduced."
        "Leave it off if Presentation Size already works with your OpenXR runtime."
        "OFXR is frame generation for VR using optical flow."
        "FidelityFX generally increases FPS by about 50% but produces more artifacts."
        "NVIDIA generally increases FPS by about 25% with fewer artifacts."
        "Off disables it."
        "Adjusts the image size in the headset.")
    string(FIND "${source}" "${required}" found)
    if(found EQUAL -1)
        message(FATAL_ERROR "Missing V1523 launcher copy: ${required}")
    endif()
endforeach()

foreach(forbidden IN ITEMS
        "L\"SteamVR\""
        "reciprocal tangent scale"
        "pixel-to-ray projection"
        "Optional OpenXR frame-generation bridge.")
    string(FIND "${source}" "${forbidden}" found)
    if(NOT found EQUAL -1)
        message(FATAL_ERROR "Superseded technical launcher copy remains: ${forbidden}")
    endif()
endforeach()

message(STATUS "V1523 concise launcher copy contract verified")
