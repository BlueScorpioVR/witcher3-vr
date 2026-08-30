#pragma once

#include <cstdint>

namespace w3vr::native_asymmetric_transport_policy {

struct ReusedCameraProjectionInput {
    bool native_asymmetric_route{};
    bool aer_presentation{};
};

// A strict-Stereo reused-camera frame now enters the same complete native
// off-axis ledger as an ordinary factory-built pair. AER retains its separate
// sequential centered producer until that route has an equivalent complete
// pair/presentation contract.
constexpr bool reused_camera_fallback_uses_native_asymmetric_projection(
    const ReusedCameraProjectionInput& input) noexcept {
    return input.native_asymmetric_route && !input.aer_presentation;
}

struct ReusedCameraEpisodeState {
    uint32_t generation{};
    uint64_t pair_id{};
    uint64_t last_present{};
    uint8_t eye_mask{};
    bool initialized{};
    bool native_armed{};
    bool current_pair_native{};
};

constexpr void reset_reused_camera_episode(
    ReusedCameraEpisodeState& state,
    uint32_t generation) noexcept {
    state = {};
    state.generation = generation;
}

// A single reused-camera eye is a normal transient around scene changes and is
// not evidence that REDengine has switched to a persistent stereo fallback.
// Freeze one projection decision for the whole pair. The first temporally
// coherent L/R pair remains centered and arms native projection only for the
// following pair; a gap, generation change or reordered pair fails closed.
constexpr bool admit_native_reused_camera_pair(
    ReusedCameraEpisodeState& state,
    uint32_t generation,
    uint64_t present,
    uint64_t pair_id,
    uint32_t eye) noexcept {
    if (pair_id == 0 || pair_id == UINT64_MAX || eye > 1) {
        return false;
    }
    const bool ordered_present = !state.initialized ||
        present >= state.last_present;
    const bool contiguous_present = !state.initialized ||
        (ordered_present && present - state.last_present <= 2);
    if (!state.initialized || state.generation != generation ||
        !contiguous_present || pair_id < state.pair_id) {
        reset_reused_camera_episode(state, generation);
    }
    if (!state.initialized || pair_id != state.pair_id) {
        state.pair_id = pair_id;
        state.eye_mask = 0;
        state.current_pair_native = state.native_armed;
    }
    state.initialized = true;
    state.last_present = present;
    state.eye_mask |= static_cast<uint8_t>(1u << eye);
    if (!state.native_armed && state.eye_mask == 0x3u) {
        state.native_armed = true;
    }
    return state.current_pair_native;
}

struct StereoFrameFallbackAdmissionInput {
    bool tagged_stereo_frame{};
    bool native_asymmetric_route{};
    bool full_vr_factory_camera_recent{};
};

// The final-frame fallback owns only REDengine's reused-camera interval. A
// recent Full-VR perspective factory has already applied the complete camera
// for an ordinary cutscene, so rewriting that frame creates a second camera
// scale and separates terrain/foliage layers.
constexpr bool stereo_frame_fallback_admissible(
    const StereoFrameFallbackAdmissionInput& input) noexcept {
    return input.tagged_stereo_frame &&
        (!input.native_asymmetric_route ||
            !input.full_vr_factory_camera_recent);
}

struct CinemaPresentationInput {
    bool packed_pair_native_asymmetric{};
    bool sequential_aer_pair_available{};
};

// The strict packed cache owns native off-axis presentation. The independent
// sequential AER Cinema cache is intentionally symmetric, even when a complete
// pair is available; promoting it was the V1248 regression.
constexpr bool cinema_presentation_uses_native_asymmetric(
    const CinemaPresentationInput& input) noexcept {
    return input.packed_pair_native_asymmetric;
}

struct PreflightInput {
    bool transport_capable{};
    bool cinema_mode{};
    bool automatic_full_vr_camera_active{};
    bool cinema_full_vr_enabled{};
    bool force_mono_cinema{};
    bool aer_presentation{};
};

constexpr bool preflight_ready(const PreflightInput& input) noexcept {
    const bool automatic_full_vr =
        !input.aer_presentation &&
        input.cinema_mode &&
        input.automatic_full_vr_camera_active &&
        input.cinema_full_vr_enabled &&
        !input.force_mono_cinema;
    return input.transport_capable &&
        (!input.cinema_mode || automatic_full_vr);
}

}  // namespace w3vr::native_asymmetric_transport_policy
