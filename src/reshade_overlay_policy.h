#pragma once

namespace w3vr::reshade_overlay {

// ReShade temporarily makes REDengine report that a menu is open while its
// own overlay owns input. Keep that state out of the game's menu route; the
// raw REDengine result becomes authoritative again as soon as the overlay
// closes.
constexpr int effective_engine_menu_state(
    int raw_engine_menu_state,
    bool reshade_overlay_open) {
    return reshade_overlay_open ? 0 : raw_engine_menu_state;
}

} // namespace w3vr::reshade_overlay
