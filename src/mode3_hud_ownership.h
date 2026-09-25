#pragma once

#include <array>
#include <cstddef>
#include <cstdint>

namespace w3vr::mode3_transport {

// The last executed HUD-family composite owns the output, not the last PSO
// binding and not any earlier scene-only draw in this command-list recording.
struct HudDrawOwnership {
    uint32_t generation{};
    bool recorded{};
    bool scene_only{};

    void record(uint32_t draw_generation, bool draw_scene_only) {
        generation = draw_generation;
        recorded = true;
        scene_only = draw_scene_only;
    }

    bool recorded_for(uint32_t expected_generation) const {
        return generation == expected_generation && recorded;
    }

    bool scene_only_for(uint32_t expected_generation) const {
        return recorded_for(expected_generation) && scene_only;
    }
};

// Capturing an exact eye's t1 does not require that eye's scene to have already
// excluded the HUD. That dependency deadlocks recovery after a freshness miss:
// stale pair -> native draw -> rejected capture -> pair stays stale forever.
constexpr bool strict_hud_capture_publishable(
    bool eye_valid, uint32_t eye, bool hud_draw_recorded) {
    return eye_valid && eye <= 1 && hud_draw_recorded;
}

// Keep the current ownership of each eye of the exact output pair. A native
// HUD publication must revoke an earlier scene-only proof for that same eye.
// Callers serialize this state with the same mutex as command-list ownership.
class HudSceneOwnership {
public:
    uint32_t generation() const { return generation_; }

    void reset(uint32_t generation) {
        generation_ = generation;
        pairs_ = {};
        cursor_ = 0;
    }

    void record(uint32_t generation, uint64_t pair_id, uint32_t eye,
                bool scene_only) {
        if (generation != generation_ || !valid_pair(pair_id) || eye > 1) {
            return;
        }
        Pair* pair = nullptr;
        for (auto& candidate : pairs_) {
            if (candidate.id == pair_id) {
                pair = &candidate;
                break;
            }
        }
        if (pair == nullptr) {
            pair = &pairs_[cursor_];
            cursor_ = (cursor_ + 1) % pairs_.size();
            *pair = {pair_id, 0};
        }
        const uint32_t eye_bit = 1u << eye;
        pair->recorded_eyes |= eye_bit;
        if (scene_only) {
            pair->scene_only_eyes |= eye_bit;
        } else {
            pair->scene_only_eyes &= ~eye_bit;
        }
    }

    bool ready(uint32_t generation, uint64_t pair_id) const {
        if (generation != generation_ || !valid_pair(pair_id)) {
            return false;
        }
        for (const auto& pair : pairs_) {
            if (pair.id == pair_id) {
                return pair.scene_only_eyes == 0x3u;
            }
        }
        return false;
    }

    // The HUD route is selected uniformly before the final scene transaction.
    // AFW may publish an accepted pair from one real eye plus one generated
    // peer, and submitted command-list metadata for ordinary stereo may arrive
    // for only one eye before that already-complete scene is presented. One
    // observed scene-only owner therefore admits the pair unless any observed
    // eye explicitly reports a native/baked HUD. A later native report revokes
    // admission immediately; missing metadata alone never creates the strobe.
    bool ready_for_composite(uint32_t generation, uint64_t pair_id) const {
        if (generation != generation_ || !valid_pair(pair_id)) {
            return false;
        }
        for (const auto& pair : pairs_) {
            if (pair.id == pair_id) {
                return pair.recorded_eyes != 0 &&
                    pair.scene_only_eyes == pair.recorded_eyes;
            }
        }
        return false;
    }

private:
    static bool valid_pair(uint64_t pair_id) {
        return pair_id != 0 && pair_id != UINT64_MAX;
    }
    struct Pair {
        uint64_t id{};
        uint32_t scene_only_eyes{};
        uint32_t recorded_eyes{};
    };
    std::array<Pair, 4> pairs_{};
    uint32_t generation_{};
    std::size_t cursor_{};
};

} // namespace w3vr::mode3_transport
