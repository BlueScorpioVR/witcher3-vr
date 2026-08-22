if(NOT DEFINED DXGI_PROXY_SOURCE OR NOT EXISTS "${DXGI_PROXY_SOURCE}")
    message(FATAL_ERROR "dxgi_proxy.cpp was not provided")
endif()

file(READ "${DXGI_PROXY_SOURCE}" dxgi_proxy)

set(required_fragments
    "g_mode3_dlss_scene_reset_requested"
    "g_mode3_dlss_scene_reset_pair_floor"
    "g_mode3_dlss_scene_reset_pair_ceiling"
    "g_mode3_dlss_scene_reset_mask"
    "g_engine_per_eye_temporal_camera_history = {};"
    "arm_mode3_dlss_scene_history_reset(present, \"post_loading\");"
    "arm_mode3_dlss_scene_history_reset(present, \"post_loading_poll\");"
    "arm_mode3_dlss_scene_history_reset("
    "current_present, \"cinema_exit\""
    "reset_tag.pair_id >= scene_pair_floor"
    "reset_tag.generation == scene_reset_generation"
    "reset_tag.pair_id <= scene_reset_ceiling"
    "claimed_scene_reset || claimed_projection_reset"
    "V1340 DLSS scene history reset applied"
)

foreach(fragment IN LISTS required_fragments)
    string(FIND "${dxgi_proxy}" "${fragment}" position)
    if(position EQUAL -1)
        message(FATAL_ERROR
            "Missing Mode-3 DLSS scene-history contract: ${fragment}")
    endif()
endforeach()

string(FIND "${dxgi_proxy}"
    "void __fastcall hook_sl_set_constants(" constants_begin)
if(constants_begin EQUAL -1)
    message(FATAL_ERROR "Missing Streamline constants hook")
endif()
string(SUBSTRING "${dxgi_proxy}" ${constants_begin} -1 constants_body)
string(FIND "${constants_body}"
    "static_cast<uint8_t*>(constants)[0x19F] = 1;" reset_position)
string(FIND "${constants_body}"
    "g_sl_set_constants(constants, frame_token, viewport);" forward_position)
if(reset_position EQUAL -1 OR forward_position EQUAL -1 OR
        NOT reset_position LESS forward_position)
    message(FATAL_ERROR
        "The exact scene reset must reach Streamline before forwarding constants")
endif()

message(STATUS "Mode-3 DLSS scene-history contract verified")
