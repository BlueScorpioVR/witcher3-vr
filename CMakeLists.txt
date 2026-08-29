cmake_minimum_required(VERSION 3.24)
project(witcher3vr VERSION 0.1411.0 LANGUAGES C CXX RC)

include(CTest)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>")

set(W3VR_DEPENDENCIES_DIR "${CMAKE_CURRENT_SOURCE_DIR}/external" CACHE PATH
    "Directory populated by scripts/setup-dependencies.ps1")

set(W3VR_MINHOOK_DIR "${W3VR_DEPENDENCIES_DIR}/minhook")
set(W3VR_OPENXR_DIR "${W3VR_DEPENDENCIES_DIR}/openxr-sdk")
set(W3VR_DIRECTX_HEADERS_DIR "${W3VR_DEPENDENCIES_DIR}/directx-headers")
set(W3VR_STREAMLINE_DIR "${W3VR_DEPENDENCIES_DIR}/streamline")
set(W3VR_RENDERDOC_DIR "${W3VR_DEPENDENCIES_DIR}/renderdoc")

foreach(required_path IN ITEMS
    "${W3VR_MINHOOK_DIR}/include/MinHook.h"
    "${W3VR_OPENXR_DIR}/include/openxr/openxr.h"
    "${W3VR_DIRECTX_HEADERS_DIR}/include/directx/d3d12.h"
    "${W3VR_STREAMLINE_DIR}/external/ngx-sdk/include/nvsdk_ngx.h"
    "${W3VR_RENDERDOC_DIR}/renderdoc_app.h")
    if(NOT EXISTS "${required_path}")
        message(FATAL_ERROR
            "Missing dependency file: ${required_path}\n"
            "Run scripts/setup-dependencies.ps1 before configuring.")
    endif()
endforeach()

add_library(minhook STATIC
    "${W3VR_MINHOOK_DIR}/src/buffer.c"
    "${W3VR_MINHOOK_DIR}/src/hook.c"
    "${W3VR_MINHOOK_DIR}/src/trampoline.c"
    "${W3VR_MINHOOK_DIR}/src/hde/hde64.c"
)
target_include_directories(minhook PUBLIC
    "${W3VR_MINHOOK_DIR}/include"
    "${W3VR_MINHOOK_DIR}/src/hde"
)

add_library(witcher3vr_dxgi SHARED
    src/aer_scheduler.cpp
    src/dxgi_proxy.cpp
    src/dxgi_proxy.def
    src/foliage_shader_resources.rc
    src/openxr_eye_geometry.cpp
    src/pipeline_flight_recorder.cpp
    src/route_flight_recorder.cpp
    src/puredark_afw_bridge.cpp
    src/puredark_afw_camera.cpp
    src/rt_ingress_join.cpp
)
target_compile_definitions(witcher3vr_dxgi PRIVATE
    WIN32_LEAN_AND_MEAN
    NOMINMAX
)
target_include_directories(witcher3vr_dxgi PRIVATE
    "${W3VR_OPENXR_DIR}/include"
    "${W3VR_DIRECTX_HEADERS_DIR}/include"
    "${W3VR_STREAMLINE_DIR}/external/ngx-sdk/include"
    "${W3VR_RENDERDOC_DIR}"
)
target_link_libraries(witcher3vr_dxgi PRIVATE
    minhook
    d3d12
    dxguid
    # WaitOnAddress/WakeByAddressAll for the engine pair producer barrier.
    Synchronization
)
set_target_properties(witcher3vr_dxgi PROPERTIES OUTPUT_NAME dxgi)
target_link_options(witcher3vr_dxgi PRIVATE /MAP)

if(BUILD_TESTING)
    add_executable(w3vr_optiscaler_jitter_policy_tests
        tests/optiscaler_jitter_policy_tests.cpp
    )
    target_include_directories(w3vr_optiscaler_jitter_policy_tests PRIVATE src)
    add_test(NAME renderer_optiscaler_jitter_policy
        COMMAND w3vr_optiscaler_jitter_policy_tests)

    add_executable(w3vr_shadow_cascade_authority_policy_tests
        tests/shadow_cascade_authority_policy_tests.cpp
    )
    target_include_directories(w3vr_shadow_cascade_authority_policy_tests
        PRIVATE src)
    add_test(NAME renderer_shadow_cascade_authority_policy
        COMMAND w3vr_shadow_cascade_authority_policy_tests)

    add_executable(w3vr_taau_submission_policy_tests
        tests/taau_submission_policy_tests.cpp
    )
    target_include_directories(w3vr_taau_submission_policy_tests PRIVATE src)
    add_test(NAME renderer_taau_submission_policy
        COMMAND w3vr_taau_submission_policy_tests)

    add_executable(w3vr_aer_scheduler_tests
        tests/aer_scheduler_tests.cpp
        src/aer_scheduler.cpp
    )
    target_include_directories(w3vr_aer_scheduler_tests PRIVATE src)
    add_test(NAME renderer_aer_scheduler COMMAND w3vr_aer_scheduler_tests)

    add_executable(w3vr_puredark_afw_bridge_tests
        tests/puredark_afw_bridge_tests.cpp
        src/puredark_afw_bridge.cpp
    )
    target_include_directories(w3vr_puredark_afw_bridge_tests PRIVATE src)
    target_compile_definitions(w3vr_puredark_afw_bridge_tests PRIVATE
        UNICODE
        _UNICODE
    )
    target_link_libraries(w3vr_puredark_afw_bridge_tests PRIVATE
        d3d12
        dxgi
    )
    add_test(NAME renderer_puredark_afw_bridge
        COMMAND w3vr_puredark_afw_bridge_tests)

    add_executable(w3vr_puredark_afw_camera_tests
        tests/puredark_afw_camera_tests.cpp
        src/puredark_afw_camera.cpp
    )
    target_include_directories(w3vr_puredark_afw_camera_tests PRIVATE src)
    target_compile_definitions(w3vr_puredark_afw_camera_tests PRIVATE
        UNICODE
        _UNICODE
    )
    add_test(NAME renderer_puredark_afw_camera
        COMMAND w3vr_puredark_afw_camera_tests)

    add_executable(w3vr_openxr_eye_geometry_tests
        tests/openxr_eye_geometry_tests.cpp
        src/openxr_eye_geometry.cpp
    )
    target_include_directories(w3vr_openxr_eye_geometry_tests PRIVATE
        src
        "${W3VR_OPENXR_DIR}/include"
    )
    add_test(NAME renderer_eye_geometry COMMAND w3vr_openxr_eye_geometry_tests)

    add_executable(w3vr_rt_ingress_join_tests
        tests/rt_ingress_join_tests.cpp
        src/rt_ingress_join.cpp
    )
    target_include_directories(w3vr_rt_ingress_join_tests PRIVATE src)
    add_test(NAME renderer_rt_ingress_join
        COMMAND w3vr_rt_ingress_join_tests)

    add_executable(w3vr_first_person_strafe_policy_tests
        tests/first_person_strafe_policy_tests.cpp
    )
    add_test(
        NAME first_person_strafe_policy
        COMMAND w3vr_first_person_strafe_policy_tests
    )

    add_executable(w3vr_first_person_combat_lock_tests
        tests/first_person_combat_lock_tests.cpp
    )
    target_include_directories(w3vr_first_person_combat_lock_tests PRIVATE src)
    add_test(
        NAME first_person_combat_lock
        COMMAND w3vr_first_person_combat_lock_tests
    )

    add_executable(w3vr_first_person_anchor_smoothing_tests
        tests/first_person_anchor_smoothing_tests.cpp
    )
    target_include_directories(
        w3vr_first_person_anchor_smoothing_tests PRIVATE src)
    add_test(
        NAME first_person_anchor_smoothing
        COMMAND w3vr_first_person_anchor_smoothing_tests
    )

    add_executable(w3vr_first_person_horse_gallop_offset_tests
        tests/first_person_horse_gallop_offset_tests.cpp
    )
    target_include_directories(
        w3vr_first_person_horse_gallop_offset_tests PRIVATE src)
    add_test(
        NAME first_person_horse_gallop_offset
        COMMAND w3vr_first_person_horse_gallop_offset_tests
    )

    add_executable(w3vr_hmd_camera_orientation_tests
        tests/hmd_camera_orientation_tests.cpp
        src/openxr_eye_geometry.cpp
    )
    target_include_directories(w3vr_hmd_camera_orientation_tests PRIVATE
        src
        "${W3VR_OPENXR_DIR}/include"
    )
    add_test(
        NAME hmd_camera_orientation
        COMMAND w3vr_hmd_camera_orientation_tests
    )

    add_executable(w3vr_cinema_aspect_tests
        tests/cinema_aspect_tests.cpp
    )
    target_include_directories(w3vr_cinema_aspect_tests PRIVATE src)
    add_test(
        NAME cinema_aspect
        COMMAND w3vr_cinema_aspect_tests
    )

    add_executable(w3vr_camera_follow_policy_tests
        tests/camera_follow_policy_tests.cpp
    )
    target_include_directories(w3vr_camera_follow_policy_tests PRIVATE launcher)
    add_test(
        NAME camera_follow_policy
        COMMAND w3vr_camera_follow_policy_tests
    )

    add_executable(w3vr_static_hud_policy_tests
        tests/static_hud_policy_tests.cpp
    )
    target_include_directories(w3vr_static_hud_policy_tests PRIVATE launcher)
    add_test(
        NAME static_hud_policy
        COMMAND w3vr_static_hud_policy_tests
    )

    add_executable(w3vr_mode3_transport_policy_tests
        tests/mode3_transport_policy_tests.cpp
    )
    target_include_directories(w3vr_mode3_transport_policy_tests PRIVATE src)
    add_test(
        NAME renderer_mode3_transport_policy
        COMMAND w3vr_mode3_transport_policy_tests
    )

    add_executable(w3vr_mode3_dlss_constants_policy_tests
        tests/mode3_dlss_constants_policy_tests.cpp
    )
    target_include_directories(
        w3vr_mode3_dlss_constants_policy_tests PRIVATE src)
    add_test(
        NAME renderer_mode3_dlss_constants_policy
        COMMAND w3vr_mode3_dlss_constants_policy_tests
    )

    add_executable(w3vr_native_asymmetric_transport_policy_tests
        tests/native_asymmetric_transport_policy_tests.cpp
    )
    target_include_directories(
        w3vr_native_asymmetric_transport_policy_tests PRIVATE src)
    add_test(
        NAME renderer_native_asymmetric_transport_policy
        COMMAND w3vr_native_asymmetric_transport_policy_tests
    )

    add_executable(w3vr_pipeline_flight_thread_tests
        tests/pipeline_flight_thread_tests.cpp
        src/pipeline_flight_recorder.cpp
    )
    target_include_directories(w3vr_pipeline_flight_thread_tests PRIVATE
        src
        "${W3VR_DIRECTX_HEADERS_DIR}/include"
    )
    target_compile_definitions(w3vr_pipeline_flight_thread_tests PRIVATE
        WIN32_LEAN_AND_MEAN
        NOMINMAX
    )
    target_link_libraries(w3vr_pipeline_flight_thread_tests PRIVATE
        d3d12
        dxguid
    )
    add_test(
        NAME pipeline_flight_thread_placement
        COMMAND w3vr_pipeline_flight_thread_tests
    )

    add_executable(w3vr_route_flight_recorder_tests
        tests/route_flight_recorder_tests.cpp
        src/route_flight_recorder.cpp
    )
    target_include_directories(w3vr_route_flight_recorder_tests PRIVATE src)
    target_compile_definitions(w3vr_route_flight_recorder_tests PRIVATE
        WIN32_LEAN_AND_MEAN
        NOMINMAX
    )
    add_test(
        NAME route_flight_recorder
        COMMAND w3vr_route_flight_recorder_tests
    )

    add_executable(w3vr_cbv_descriptor_cache_policy_tests
        tests/cbv_descriptor_cache_policy_tests.cpp
    )
    target_include_directories(w3vr_cbv_descriptor_cache_policy_tests PRIVATE src)
    add_test(
        NAME renderer_cbv_descriptor_cache_policy
        COMMAND w3vr_cbv_descriptor_cache_policy_tests
    )

    add_executable(w3vr_foliage_shader_orientation_policy_tests
        tests/foliage_shader_orientation_policy_tests.cpp
    )
    target_include_directories(
        w3vr_foliage_shader_orientation_policy_tests PRIVATE src)
    add_test(
        NAME renderer_foliage_shader_orientation_policy
        COMMAND w3vr_foliage_shader_orientation_policy_tests
    )

    add_test(
        NAME renderer_foliage_fixed_only_contract
        COMMAND "${CMAKE_COMMAND}"
            "-DDXGI_PROXY_SOURCE=${CMAKE_CURRENT_SOURCE_DIR}/src/dxgi_proxy.cpp"
            -P "${CMAKE_CURRENT_SOURCE_DIR}/tests/foliage_fixed_only_contract.cmake"
    )

    set(W3VR_DXC_EXECUTABLE
        "C:/Program Files (x86)/Windows Kits/10/bin/${CMAKE_VS_WINDOWS_TARGET_PLATFORM_VERSION}/x64/dxc.exe")
    if(EXISTS "${W3VR_DXC_EXECUTABLE}")
        add_test(
            NAME renderer_foliage_dxil_b12_load_contract
            COMMAND "${CMAKE_COMMAND}"
                "-DDXC_EXECUTABLE=${W3VR_DXC_EXECUTABLE}"
                "-DDISTANT_SHADER=${CMAKE_CURRENT_SOURCE_DIR}/src/shaders/foliage_distant_b12_orientation.dxil"
                "-DFROND_SHADER=${CMAKE_CURRENT_SOURCE_DIR}/src/shaders/foliage_frond_b12_orientation.dxil"
                -P "${CMAKE_CURRENT_SOURCE_DIR}/tests/foliage_dxil_b12_load_contract.cmake"
        )
    endif()

    add_test(
        NAME hud_editor_subtitle_preview_nudge_contract
        COMMAND "${CMAKE_COMMAND}"
            "-DHUD_EDITOR_SCRIPT=${CMAKE_CURRENT_SOURCE_DIR}/support/modWitcher3VRHUDEditor/content/scripts/local/witcher3vr_hud_editor/hud_editor.ws"
            -P "${CMAKE_CURRENT_SOURCE_DIR}/tests/hud_editor_subtitle_preview_nudge_contract.cmake"
    )

    add_test(
        NAME renderer_mode3_projection_transition_contract
        COMMAND "${CMAKE_COMMAND}"
            "-DDXGI_PROXY_SOURCE=${CMAKE_CURRENT_SOURCE_DIR}/src/dxgi_proxy.cpp"
            -P "${CMAKE_CURRENT_SOURCE_DIR}/tests/mode3_projection_transition_contract.cmake"
    )

    add_test(
        NAME renderer_mode3_hud_projection_lifecycle_contract
        COMMAND "${CMAKE_COMMAND}"
            "-DDXGI_PROXY_SOURCE=${CMAKE_CURRENT_SOURCE_DIR}/src/dxgi_proxy.cpp"
            -P "${CMAKE_CURRENT_SOURCE_DIR}/tests/mode3_hud_projection_lifecycle_contract.cmake"
    )

    add_test(
        NAME renderer_mode3_afw_pixel_projection_contract
        COMMAND "${CMAKE_COMMAND}"
            "-DDXGI_PROXY_SOURCE=${CMAKE_CURRENT_SOURCE_DIR}/src/dxgi_proxy.cpp"
            -P "${CMAKE_CURRENT_SOURCE_DIR}/tests/mode3_afw_pixel_projection_contract.cmake"
    )

    add_test(
        NAME renderer_afw_native_motion_contract
        COMMAND "${CMAKE_COMMAND}"
            "-DDXGI_PROXY_SOURCE=${CMAKE_CURRENT_SOURCE_DIR}/src/dxgi_proxy.cpp"
            -P "${CMAKE_CURRENT_SOURCE_DIR}/tests/afw_native_motion_contract.cmake"
    )

    add_test(
        NAME renderer_mode3_asymmetric_effect_contract
        COMMAND "${CMAKE_COMMAND}"
            "-DDXGI_PROXY_SOURCE=${CMAKE_CURRENT_SOURCE_DIR}/src/dxgi_proxy.cpp"
            -P "${CMAKE_CURRENT_SOURCE_DIR}/tests/mode3_asymmetric_effect_contract.cmake"
    )

    add_test(
        NAME renderer_taau_cb10_producer_identity_contract
        COMMAND "${CMAKE_COMMAND}"
            "-DDXGI_PROXY_SOURCE=${CMAKE_CURRENT_SOURCE_DIR}/src/dxgi_proxy.cpp"
            -P "${CMAKE_CURRENT_SOURCE_DIR}/tests/taau_cb10_producer_identity_contract.cmake"
    )

    add_test(
        NAME renderer_dlss_per_eye_constants_contract
        COMMAND "${CMAKE_COMMAND}"
            "-DDXGI_PROXY_SOURCE=${CMAKE_CURRENT_SOURCE_DIR}/src/dxgi_proxy.cpp"
            -P "${CMAKE_CURRENT_SOURCE_DIR}/tests/dlss_per_eye_constants_contract.cmake"
    )

    add_test(
        NAME renderer_optiscaler_direct_ngx_contract
        COMMAND "${CMAKE_COMMAND}"
            "-DDXGI_PROXY_SOURCE=${CMAKE_CURRENT_SOURCE_DIR}/src/dxgi_proxy.cpp"
            "-DOPTISCALER_BRIDGE_INI=${CMAKE_CURRENT_SOURCE_DIR}/optiscaler_bridge.ini"
            -P "${CMAKE_CURRENT_SOURCE_DIR}/tests/optiscaler_direct_ngx_contract.cmake"
    )

    add_test(
        NAME renderer_cross_queue_retained_hud_ownership_contract
        COMMAND "${CMAKE_COMMAND}"
            "-DDXGI_PROXY_SOURCE=${CMAKE_CURRENT_SOURCE_DIR}/src/dxgi_proxy.cpp"
            -P "${CMAKE_CURRENT_SOURCE_DIR}/tests/cross_queue_retained_hud_ownership_contract.cmake"
    )

    add_test(
        NAME renderer_per_queue_private_slot_retirement_contract
        COMMAND "${CMAKE_COMMAND}"
            "-DDXGI_PROXY_SOURCE=${CMAKE_CURRENT_SOURCE_DIR}/src/dxgi_proxy.cpp"
            -P "${CMAKE_CURRENT_SOURCE_DIR}/tests/per_queue_private_slot_retirement_contract.cmake"
    )

    add_test(
        NAME renderer_cross_queue_scene_capture_ownership_contract
        COMMAND "${CMAKE_COMMAND}"
            "-DDXGI_PROXY_SOURCE=${CMAKE_CURRENT_SOURCE_DIR}/src/dxgi_proxy.cpp"
            -P "${CMAKE_CURRENT_SOURCE_DIR}/tests/cross_queue_scene_capture_ownership_contract.cmake"
    )

    add_test(
        NAME renderer_cross_queue_rt_history_ownership_contract
        COMMAND "${CMAKE_COMMAND}"
            "-DDXGI_PROXY_SOURCE=${CMAKE_CURRENT_SOURCE_DIR}/src/dxgi_proxy.cpp"
            -P "${CMAKE_CURRENT_SOURCE_DIR}/tests/cross_queue_rt_history_ownership_contract.cmake"
    )

    add_test(
        NAME renderer_presentation_size_final_only_contract
        COMMAND "${CMAKE_COMMAND}"
            "-DDXGI_PROXY_SOURCE=${CMAKE_CURRENT_SOURCE_DIR}/src/dxgi_proxy.cpp"
            -P "${CMAKE_CURRENT_SOURCE_DIR}/tests/presentation_size_final_only_contract.cmake"
    )

    add_test(
        NAME renderer_clean_mode1_contract
        COMMAND "${CMAKE_COMMAND}"
            "-DDXGI_PROXY_SOURCE=${CMAKE_CURRENT_SOURCE_DIR}/src/dxgi_proxy.cpp"
            -P "${CMAKE_CURRENT_SOURCE_DIR}/tests/clean_mode1_renderer_contract.cmake"
    )

    add_test(
        NAME launcher_v1414_ui_contract
        COMMAND "${CMAKE_COMMAND}"
            "-DLAUNCHER_MAIN=${CMAKE_CURRENT_SOURCE_DIR}/launcher/main.cpp"
            "-DLAUNCHER_CONFIG=${CMAKE_CURRENT_SOURCE_DIR}/launcher/config.cpp"
            "-DLAUNCHER_HEADER=${CMAKE_CURRENT_SOURCE_DIR}/launcher/config.h"
            "-DLAUNCHER_DEFAULTS=${CMAKE_CURRENT_SOURCE_DIR}/launcher/witcher3vr.default.ini"
            "-DSTARTUP_CHECKS=${CMAKE_CURRENT_SOURCE_DIR}/launcher/startup_checks.cpp"
            "-DDXGI_PROXY_SOURCE=${CMAKE_CURRENT_SOURCE_DIR}/src/dxgi_proxy.cpp"
            -P "${CMAKE_CURRENT_SOURCE_DIR}/tests/launcher_v1414_ui_contract.cmake"
    )

endif()

option(W3VR_BUILD_LAUNCHER "Build the Witcher 3 VR launcher" ON)
if(W3VR_BUILD_LAUNCHER)
    add_subdirectory(launcher)
endif()
