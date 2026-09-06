file(READ "${SOURCE_ROOT}/src/dxgi_proxy.cpp" renderer)
file(READ "${SOURCE_ROOT}/src/openxr_eye_geometry.cpp" geometry)
file(READ "${SOURCE_ROOT}/src/openxr_eye_geometry.h" geometry_header)
file(READ "${SOURCE_ROOT}/launcher/main.cpp" launcher)
file(READ "${SOURCE_ROOT}/launcher/config.h" config_header)
file(READ "${SOURCE_ROOT}/launcher/managed_runtime.cpp" managed)

foreach(retired IN ITEMS presentation_black_resize BlackResizePresentation
        derive_black_resize_presentation g_xr_presentation_window
        initialize_presentation_window_pipeline render_presentation_black_resize
        IdPresentationBlackResize "Alt. resize")
    string(FIND "${renderer}${geometry}${geometry_header}${launcher}${config_header}"
        "${retired}" position)
    if(NOT position EQUAL -1)
        message(FATAL_ERROR "Retired alternate resize implementation remains: ${retired}")
    endif()
endforeach()

foreach(required IN ITEMS
        "float presentation_producer_scale()"
        "cover_scale * presentation_scale"
        "submitted_fov=producer"
        "for (auto*& allocator : g_xr_command_allocators)"
        "g_xr_fence_event = CreateEventA"
        "g_xr_views.assign(2, {XR_TYPE_VIEW})")
    string(FIND "${renderer}" "${required}" position)
    if(position EQUAL -1)
        message(FATAL_ERROR "Required surviving presentation/lifecycle missing: ${required}")
    endif()
endforeach()

file(READ "${SOURCE_ROOT}/CMakeLists.txt" project_config)
string(REGEX MATCH "VERSION 0[.]([0-9]+)[.]0" version_match "${project_config}")
set(release_version "${CMAKE_MATCH_1}")
foreach(required IN ITEMS "NVIDIA med. 50%" "Witcher 3 VR Launcher - V${release_version}")
    string(FIND "${launcher}" "${required}" position)
    if(position EQUAL -1)
        message(FATAL_ERROR "Missing release launcher label: ${required}")
    endif()
endforeach()

foreach(required IN ITEMS "renodx-dlss5-v2.5.addon64"
        "!use_dlss5_addon")
    string(FIND "${managed}" "${required}" position)
    if(position EQUAL -1)
        message(FATAL_ERROR "Missing ReShade add-on ownership: ${required}")
    endif()
endforeach()

foreach(retired IN ITEMS "ReshadeDlss5Cheeky" "NrEnabled"
        "use_cheeky_addon")
    string(FIND "${managed}${config_header}" "${retired}" position)
    if(NOT position EQUAL -1)
        message(FATAL_ERROR "Retired Cheeky launcher path remains: ${retired}")
    endif()
endforeach()
