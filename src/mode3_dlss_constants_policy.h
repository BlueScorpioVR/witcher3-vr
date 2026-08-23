#pragma once

#include <cstdint>

namespace w3vr::mode3_dlss_constants {

struct Receipt {
    uint64_t pair_id{};
    uint32_t generation{};
    uint32_t frame_token{};
    bool reset{};

    [[nodiscard]] bool matches(
        uint64_t expected_pair_id,
        uint32_t expected_generation) const noexcept {
        return pair_id != 0 && pair_id != UINT64_MAX &&
            pair_id == expected_pair_id && generation == expected_generation;
    }
};

struct BuilderDecision {
    bool target_current{};
    bool peer_current{};
    bool invoke{};
    bool forward_reset{};
};

// REDengine's common DLSS constants builder is guarded by the frame id at
// state+0x6c and normally executes only for the first sequential eye. Re-enter
// it only for the missing strict-Stereo eye after the peer's real constants
// have proved that the native builder completed for this exact pair. AER owns
// its own two-eye publication and must remain untouched.
[[nodiscard]] inline BuilderDecision decide_builder_reentry(
    bool sequential_dlss,
    bool aer_presentation,
    int render_eye,
    uint64_t pair_id,
    uint32_t generation,
    uint32_t frame_id,
    uint32_t builder_guard_frame,
    const Receipt& target,
    const Receipt& peer) noexcept {
    BuilderDecision decision{};
    decision.target_current = target.matches(pair_id, generation);
    decision.peer_current = peer.matches(pair_id, generation);
    decision.invoke = sequential_dlss && !aer_presentation &&
        render_eye == 0 && pair_id != 0 && pair_id != UINT64_MAX &&
        decision.peer_current && !decision.target_current &&
        builder_guard_frame == frame_id;
    decision.forward_reset = decision.invoke && peer.reset;
    return decision;
}

}  // namespace w3vr::mode3_dlss_constants
