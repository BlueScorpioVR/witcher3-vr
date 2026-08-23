if(NOT DEFINED DXGI_PROXY_SOURCE OR NOT EXISTS "${DXGI_PROXY_SOURCE}")
    message(FATAL_ERROR "DXGI proxy source is required")
endif()

file(READ "${DXGI_PROXY_SOURCE}" source)

foreach(required_fragment IN ITEMS
        "constexpr int kOpenXrModeCleanMono = 1;"
        "int openxr_mode{1};"
        "configured_openxr_mode == kOpenXrModeStereo"
        "? kOpenXrModeStereo"
        ": kOpenXrModeCleanMono;"
        "bool clean_mono_transport_active()"
        "bool selected_resolution_full_image_transport_active()"
        "g_config.engine_dual_render_probe = false;"
        "g_config.engine_dual_render_start = false;"
        "g_config.engine_sync_swap_eyes = false;"
        "g_config.engine_native_stereo_offset = 0.0f;"
        "g_config.engine_factory_stereo_offset = 0.0f;"
        "g_config.raytracing_enabled = false;"
        "clean_mono_unified_openxr_submit"
        "fit_projection_sources[0] == game_backbuffer"
        "fit_projection_sources[1] == game_backbuffer"
        "clean_mono_symmetric_subimage"
        "derive_symmetric_eye_subimage("
        "projection_eye_exact_fovs[eye]"
        "producer=one pose=cyclopean shift=0"
        "g_clean_mono_render_views_valid"
        "g_clean_mono_cinema_hud_pso"
        "g_clean_mono_auto_cinema_hud_pso"
        "g_clean_mono_full_vr_hud_pso"
        "V19002 clean Mono HUD route kind=%s"
        "g_clean_mono_dlss_temporal_tokens"
        "clean_mono_camera_to_previous_transform("
        "dispatch_clean_mono_dlss_camera_motion("
        "V19003 clean Mono DLSS consumed token=%u"
        "g_clean_mono_dlss_render_views_valid")
    string(FIND "${source}" "${required_fragment}" fragment_index)
    if(fragment_index EQUAL -1)
        message(FATAL_ERROR
            "Missing clean Mode-1 renderer contract: ${required_fragment}")
    endif()
endforeach()

# V209/V210: one Streamline token owns one consumed camera and its carried
# render views. The previous-camera reference advances only after the original
# DLSS evaluation reports success; Mode 3 must never enter this correction.
string(FIND "${source}"
    "bool dispatch_clean_mono_dlss_camera_motion(" mono_dlss_dispatch_begin)
string(FIND "${source}"
    "uint32_t streamline_eye()" mono_dlss_dispatch_end)
if(mono_dlss_dispatch_begin EQUAL -1 OR mono_dlss_dispatch_end EQUAL -1 OR
        NOT mono_dlss_dispatch_begin LESS mono_dlss_dispatch_end)
    message(FATAL_ERROR "Clean-Mono DLSS dispatch scope was not found")
endif()
math(EXPR mono_dlss_dispatch_length
    "${mono_dlss_dispatch_end} - ${mono_dlss_dispatch_begin}")
string(SUBSTRING "${source}" ${mono_dlss_dispatch_begin}
    ${mono_dlss_dispatch_length} mono_dlss_dispatch_body)
string(FIND "${mono_dlss_dispatch_body}"
    "!clean_mono_transport_active()" mono_dlss_exact_gate)
if(mono_dlss_exact_gate EQUAL -1)
    message(FATAL_ERROR "Mono-DLSS camera correction is not Mode-1 gated")
endif()
string(FIND "${source}"
    "const int result = g_sl_evaluate_feature(" mono_dlss_eval)
string(FIND "${source}"
    "if (clean_mono_dlss_dispatched && result != 0)" mono_dlss_commit)
if(mono_dlss_eval EQUAL -1 OR mono_dlss_commit EQUAL -1 OR
        NOT mono_dlss_eval LESS mono_dlss_commit)
    message(FATAL_ERROR
        "Mono-DLSS history camera advances before successful consumption")
endif()

# The clean-Mono frontend stays in VIEW space until REDengine publishes its
# first gameplay HMD camera. Mono never enables dual rendering, so that camera
# is its readiness edge; later pause/inventory menus use the existing LOCAL
# world-locked anchor.
string(FIND "${source}"
    "const bool clean_mono_gameplay_camera_seen ="
    menu_startup_begin)
string(FIND "${source}"
    "const int spatial_panel_kind = startup_frontend_panel"
    menu_startup_end)
if(menu_startup_begin EQUAL -1 OR menu_startup_end EQUAL -1 OR
        NOT menu_startup_begin LESS menu_startup_end)
    message(FATAL_ERROR "Spatial menu startup classifier was not found")
endif()
math(EXPR menu_startup_length
    "${menu_startup_end} - ${menu_startup_begin}")
string(SUBSTRING "${source}" ${menu_startup_begin}
    ${menu_startup_length} menu_startup_body)
foreach(menu_readiness_fragment IN ITEMS
        "clean_mono_gameplay_camera_seen"
        "g_engine_hmd_camera_last_present.load(std::memory_order_acquire)"
        "(!clean_mono_transport_active() ||"
        "!clean_mono_gameplay_camera_seen)")
    string(FIND "${menu_startup_body}"
        "${menu_readiness_fragment}" menu_readiness_index)
    if(menu_readiness_index EQUAL -1)
        message(FATAL_ERROR
            "Clean Mode 1 startup menu lacks camera readiness: ${menu_readiness_fragment}")
    endif()
endforeach()

# Cinema HUD correction in Mono is intentionally one zero-shift transform.
# Per-eye convergence and Mode-3 retained-HUD ownership must not be reused.
foreach(zero_shift_fragment IN ITEMS
        "compile_hud_composite_pixel_shader(\n                    0,\n                    g_config.hud_size * g_config.manual_cinema_hud_scale"
        "compile_hud_composite_pixel_shader(\n                    0, g_config.hud_size * 1.30f"
        "compile_hud_composite_pixel_shader(\n                    0, g_config.hud_size * g_config.full_vr_hud_scale")
    string(FIND "${source}" "${zero_shift_fragment}" zero_shift_index)
    if(zero_shift_index EQUAL -1)
        message(FATAL_ERROR
            "Missing zero-shift clean-Mono Cinema HUD transform: ${zero_shift_fragment}")
    endif()
endforeach()

foreach(obsolete_fragment IN ITEMS
        "g_config.openxr_mode == 2"
        "g_config.openxr_mode != 2"
        "g_mono_hud_outputs"
        "g_mono_hud_rtv_heap"
        "ensure_mono_hud_outputs"
        "replay_mono_hud_composites"
        "mono_capture_slots"
        "mono_captured_sources"
        "g_mono_dlss_render_views")
    string(FIND "${source}" "${obsolete_fragment}" obsolete_index)
    if(NOT obsolete_index EQUAL -1)
        message(FATAL_ERROR
            "Obsolete Mode-2/dual-mono path remains: ${obsolete_fragment}")
    endif()
endforeach()

# Mode 3 must remain an exact stereo-only predicate; the clean-mono helper may
# not leak into duplicate-render, AFW or native-asymmetric producer ownership.
string(FIND "${source}" "bool mode3_stereo_transport_active()" mode3_begin)
if(mode3_begin EQUAL -1)
    message(FATAL_ERROR "Mode-3 transport predicate was not found")
endif()
string(SUBSTRING "${source}" ${mode3_begin} -1 mode3_tail)
string(FIND "${mode3_tail}" "bool mode3_aer_presentation_active() {"
    mode3_length)
if(mode3_length EQUAL -1)
    message(FATAL_ERROR "Mode-3 transport predicate boundary was not found")
endif()
string(SUBSTRING "${mode3_tail}" 0 ${mode3_length} mode3_body)
string(FIND "${mode3_body}"
    "return g_config.openxr_mode == kOpenXrModeStereo;" exact_mode3)
if(exact_mode3 EQUAL -1)
    message(FATAL_ERROR "Mode 3 is no longer an exact stereo-only predicate")
endif()
string(FIND "${mode3_body}" "clean_mono" mono_leak)
if(NOT mono_leak EQUAL -1)
    message(FATAL_ERROR "Clean mono leaked into the Mode-3 predicate")
endif()

string(FIND "${source}"
    "bool native_asymmetric_noaa_route_active() {" native_begin)
string(FIND "${source}"
    "bool automatic_focus_projection_route_configured() {" native_end)
if(native_begin EQUAL -1 OR native_end EQUAL -1 OR
        NOT native_begin LESS native_end)
    message(FATAL_ERROR "Native-asymmetric route scope was not found")
endif()
math(EXPR native_length "${native_end} - ${native_begin}")
string(SUBSTRING "${source}" ${native_begin} ${native_length} native_body)
string(FIND "${native_body}" "clean_mono" native_mono_leak)
if(NOT native_mono_leak EQUAL -1)
    message(FATAL_ERROR
        "Clean mono entered the Mode-3 native-asymmetric pair ledger")
endif()

# Clean Mode 1 consumes the common corrected-camera rebuild path even though it
# owns neither a stereo offset nor per-eye temporal history. Its trampoline must
# therefore be installed, and the private helper must fail closed if installation
# ever fails rather than attempting an indirect call through null.
string(FIND "${source}"
    "bool safe_rebuild_shadow_view(float* shadow_view) {" rebuild_safe_begin)
string(FIND "${source}"
    "float resolve_vertical_pitch_recenter(" rebuild_safe_end)
if(rebuild_safe_begin EQUAL -1 OR rebuild_safe_end EQUAL -1 OR
        NOT rebuild_safe_begin LESS rebuild_safe_end)
    message(FATAL_ERROR "Safe view-rebuild helper scope was not found")
endif()
math(EXPR rebuild_safe_length
    "${rebuild_safe_end} - ${rebuild_safe_begin}")
string(SUBSTRING "${source}" ${rebuild_safe_begin}
    ${rebuild_safe_length} rebuild_safe_body)
string(FIND "${rebuild_safe_body}"
    "shadow_view == nullptr || g_engine_view_rebuild == nullptr"
    rebuild_null_guard)
if(rebuild_null_guard EQUAL -1)
    message(FATAL_ERROR
        "Private view rebuild is not guarded against a null trampoline")
endif()

string(FIND "${source}"
    "void install_engine_view_factory_probe() {" rebuild_install_begin)
if(rebuild_install_begin EQUAL -1)
    message(FATAL_ERROR "View-rebuild hook installation scope was not found")
endif()
string(SUBSTRING "${source}" ${rebuild_install_begin} -1
    rebuild_install_tail)
string(FIND "${rebuild_install_tail}"
    "// [FIX:RENDER-PROXY-FOV-DISTANCE-AUTHORITY" rebuild_install_length)
if(rebuild_install_length EQUAL -1)
    message(FATAL_ERROR "View-rebuild hook installation boundary was not found")
endif()
string(SUBSTRING "${rebuild_install_tail}" 0
    ${rebuild_install_length} rebuild_install_body)
string(FIND "${rebuild_install_body}"
    "!clean_mono_transport_active()" rebuild_mono_owner)
if(rebuild_mono_owner EQUAL -1)
    message(FATAL_ERROR
        "Clean Mode 1 does not own the required view-rebuild hook")
endif()

# V1122's distance/LOD correction is common cyclopean geometry policy. Clean
# Mono already publishes the native gameplay FOV consumed by this hook, so both
# hook installation and per-call execution must use the common supported
# projection predicate instead of the old exact Mode-3 gate.
string(FIND "${source}"
    "float* __fastcall hook_engine_render_proxy_distance_scale("
    distance_hook_begin)
string(FIND "${source}"
    "void install_engine_render_proxy_distance_scale_hook() {"
    distance_install_begin)
string(FIND "${source}"
    "void poll_engine_menu_state() {"
    distance_install_end)
if(distance_hook_begin EQUAL -1 OR distance_install_begin EQUAL -1 OR
        distance_install_end EQUAL -1 OR
        NOT distance_hook_begin LESS distance_install_begin OR
        NOT distance_install_begin LESS distance_install_end)
    message(FATAL_ERROR "Render-proxy distance hook scopes were not found")
endif()
math(EXPR distance_hook_length
    "${distance_install_begin} - ${distance_hook_begin}")
string(SUBSTRING "${source}" ${distance_hook_begin}
    ${distance_hook_length} distance_hook_body)
math(EXPR distance_install_length
    "${distance_install_end} - ${distance_install_begin}")
string(SUBSTRING "${source}" ${distance_install_begin}
    ${distance_install_length} distance_install_body)
foreach(distance_scope IN ITEMS distance_hook_body distance_install_body)
    string(FIND "${${distance_scope}}"
        "supported_projection_transport_active()" common_route_gate)
    if(common_route_gate EQUAL -1)
        message(FATAL_ERROR
            "Clean Mono is excluded from V1122 distance authority: ${distance_scope}")
    endif()
    string(FIND "${${distance_scope}}"
        "mode3_stereo_transport_active()" stale_mode3_gate)
    if(NOT stale_mode3_gate EQUAL -1)
        message(FATAL_ERROR
            "V1122 distance authority still has an exact Mode-3 gate: ${distance_scope}")
    endif()
endforeach()

# The only producer barrier which survives must remain guarded by the exact
# Mode-3 predicate. Mode 1 may tag its natural frame, but it must never park
# that producer waiting for a peer which does not exist.
string(FIND "${source}"
    "wait_for_engine_pair_completion(produced_pair, 64);" pair_wait)
if(pair_wait EQUAL -1)
    message(FATAL_ERROR "Mode-3 producer wait contract was not found")
endif()
math(EXPR pair_wait_scope_begin "${pair_wait} - 500")
if(pair_wait_scope_begin LESS 0)
    set(pair_wait_scope_begin 0)
endif()
string(SUBSTRING "${source}" ${pair_wait_scope_begin} 500 pair_wait_guard)
string(FIND "${pair_wait_guard}"
    "if (mode3_stereo_transport_active() &&" exact_pair_wait_gate)
if(exact_pair_wait_gate EQUAL -1)
    message(FATAL_ERROR
        "Producer pair wait is no longer guarded by exact Mode 3")
endif()
string(FIND "${pair_wait_guard}" "clean_mono" pair_wait_mono_leak)
if(NOT pair_wait_mono_leak EQUAL -1)
    message(FATAL_ERROR "Clean mono entered the producer pair wait")
endif()

message(STATUS "Clean Mode-1 renderer contract verified")

