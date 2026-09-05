#include "mode3_hud_ownership.h"

#ifdef NDEBUG
#undef NDEBUG
#endif
#include <cassert>

using w3vr::mode3_transport::HudDrawOwnership;
using w3vr::mode3_transport::HudSceneOwnership;
using w3vr::mode3_transport::strict_hud_capture_publishable;

int main() {
    // A scene-only draw followed by a native HUD draw in the SAME recording
    // must not keep the positive marker used by the old generation-only map.
    HudDrawOwnership draw{};
    assert(!draw.recorded_for(0));
    assert(!draw.scene_only_for(7));
    draw.record(7, true);
    assert(draw.scene_only_for(7));
    draw.record(7, false);
    assert(draw.recorded_for(7));
    assert(!draw.recorded_for(8));
    assert(!draw.scene_only_for(7));
    draw.record(7, true);
    assert(draw.scene_only_for(7));
    assert(!draw.scene_only_for(8));
    draw = {}; // Command-list reset/consumption discards the recording.
    assert(!draw.scene_only_for(7));

    // Rebinding a PSO is not a draw: all eight-draw sequences depend only on
    // the final executed HUD-family composite, not any earlier positive draw.
    for (uint32_t sequence = 0; sequence < 256; ++sequence) {
        draw = {};
        for (uint32_t step = 0; step < 8; ++step) {
            const bool scene_only = (sequence & (1u << step)) != 0;
            draw.record(7, scene_only);
            assert(draw.scene_only_for(7) == scene_only);
        }
    }

    HudSceneOwnership scenes{};
    scenes.reset(7);
    assert(scenes.generation() == 7);
    assert(!scenes.ready(7, 42));
    scenes.record(7, 42, 0, true);
    assert(!scenes.ready(7, 42));
    scenes.record(7, 42, 1, true);
    assert(scenes.ready(7, 42));

    // A later native publication revokes a COMPLETED pair. The old positive
    // pair-ID history kept returning true here and authorized duplicate HUD.
    scenes.record(7, 42, 0, false);
    assert(!scenes.ready(7, 42));
    scenes.record(7, 42, 1, true);
    assert(!scenes.ready(7, 42)); // Other eye cannot repair this eye's ownership.
    scenes.record(7, 42, 0, true);
    assert(scenes.ready(7, 42)); // A real replacement can restore scene-only.
    scenes.record(7, 42, 1, false);
    assert(!scenes.ready(7, 42));

    // Recover from a stale retained pair without assuming it is already
    // scene-only. Both native eye captures can be admitted; late composition
    // stays forbidden on their baked output until actual clean draws follow.
    scenes.reset(7);
    draw.record(7, false);
    assert(strict_hud_capture_publishable(true, 0, draw.recorded_for(7)));
    assert(strict_hud_capture_publishable(true, 1, draw.recorded_for(7)));
    assert(!strict_hud_capture_publishable(false, 0, true));
    assert(!strict_hud_capture_publishable(true, 2, true));
    assert(!strict_hud_capture_publishable(true, UINT32_MAX, true));
    assert(!strict_hud_capture_publishable(true, 0, false));
    scenes.record(7, 50, 0, draw.scene_only_for(7));
    scenes.record(7, 50, 1, draw.scene_only_for(7));
    assert(!scenes.ready(7, 50));
    draw.record(7, true);
    scenes.record(7, 51, 0, draw.scene_only_for(7));
    scenes.record(7, 51, 1, draw.scene_only_for(7));
    assert(scenes.ready(7, 51));
    assert(!scenes.ready(7, 50));

    // Interleaved pairs retain independent eye identities; a half-pair or a
    // repeat of one eye cannot certify another output pair.
    scenes.reset(7);
    scenes.record(7, 41, 0, true);
    scenes.record(7, 42, 0, true);
    scenes.record(7, 42, 0, true);
    assert(!scenes.ready(7, 41) && !scenes.ready(7, 42));
    scenes.record(7, 41, 1, true);
    assert(scenes.ready(7, 41) && !scenes.ready(7, 42));
    scenes.record(7, 42, 1, true);
    assert(scenes.ready(7, 41) && scenes.ready(7, 42));
    scenes.record(7, 42, 1, false);
    assert(scenes.ready(7, 41) && !scenes.ready(7, 42));

    // Invalid/stale publications cannot revoke a current pair or certify one.
    scenes.record(6, 41, 0, false);
    scenes.record(8, 41, 0, false);
    scenes.record(7, 41, 2, false);
    scenes.record(7, 41, UINT32_MAX, false);
    assert(scenes.ready(7, 41));
    assert(!scenes.ready(6, 41));
    scenes.record(7, 0, 0, true);
    scenes.record(7, 0, 1, true);
    scenes.record(7, UINT64_MAX, 0, true);
    scenes.record(7, UINT64_MAX, 1, true);
    assert(!scenes.ready(7, 0) && !scenes.ready(7, UINT64_MAX));
    scenes.reset(8);
    assert(!scenes.ready(8, 41) && !scenes.ready(7, 41));
    scenes.record(7, 41, 0, true);
    scenes.record(7, 41, 1, true);
    assert(!scenes.ready(8, 41));

    // Bounded history replaces old entries without borrowing their clean eyes.
    scenes.reset(9);
    for (uint64_t pair = 1; pair <= 4; ++pair) {
        scenes.record(9, pair, 0, true);
        scenes.record(9, pair, 1, true);
    }
    scenes.record(9, 5, 0, true);
    assert(!scenes.ready(9, 1) && !scenes.ready(9, 5));
    assert(scenes.ready(9, 2) && scenes.ready(9, 4));
    scenes.record(9, 5, 1, true);
    assert(scenes.ready(9, 5));

    // Exhaustive eye/ownership updates of an exact pair agree with the last
    // output of EACH eye (four possibilities per submission, eight updates).
    for (uint32_t sequence = 0; sequence < 65536; ++sequence) {
        scenes.reset(10);
        bool left = false;
        bool right = false;
        for (uint32_t step = 0; step < 8; ++step) {
            const uint32_t update = (sequence >> (2 * step)) & 3u;
            const uint32_t eye = update & 1u;
            const bool clean = (update & 2u) != 0;
            (eye == 0 ? left : right) = clean;
            scenes.record(10, 100, eye, clean);
            assert(scenes.ready(10, 100) == (left && right));
        }
    }
    return 0;
}
