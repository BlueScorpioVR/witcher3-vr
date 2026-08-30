#pragma once

#include <cstdint>

namespace w3vr::native_asymmetric_transport_policy {

// A native off-axis raster always needs the exact factory proof. Temporal
// descriptors are additional ownership only when a temporal backend exists;
// No AA has no history transaction to certify.
constexpr bool native_temporal_proof_sufficient(
    bool temporal_backend_active,
    uint8_t temporal_mask,
    uint8_t required_mask) noexcept {
    return !temporal_backend_active ||
        (temporal_mask & required_mask) == required_mask;
}

struct ReusedCameraProjectionInput {
    bool native_asymmetric_route{};
};

// A reused-camera frame enters the same complete native off-axis ledger as an
// ordinary factory-built pair. Stereo and AER differ only in presentation
// cadence; neither may reinterpret an admitted off-axis frame as symmetric.
constexpr bool reused_camera_fallback_uses_native_asymmetric_projection(
    const ReusedCameraProjectionInput& input) noexcept {
    return input.native_asymmetric_route;
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
    bool sequential_aer_pair_native_asymmetric{};
};

struct CinemaPairInput {
    bool native_asymmetric_required{};
    bool slot_matches_pair_and_generation{};
    bool views_complete{};
    uint8_t factory_mask{};
    uint8_t temporal_mask{};
    uint8_t dlss_input_mask{};
    bool temporal_backend_active{};
    bool dlss_input_required{};
};

// Automatic Full VR may publish off-axis pixels only after both exact eyes,
// views and every backend-specific producer proof belong to one pair.
constexpr bool cinema_pair_admissible(
    const CinemaPairInput& input) noexcept {
    if (!input.native_asymmetric_required) {
        return true;
    }
    return input.slot_matches_pair_and_generation &&
        input.views_complete &&
        input.factory_mask == 0x3u &&
        native_temporal_proof_sufficient(
            input.temporal_backend_active, input.temporal_mask, 0x3u) &&
        (!input.dlss_input_required || input.dlss_input_mask == 0x3u);
}

// Each cache carries the projection class of the immutable pixels it owns.
// The final presenter must use that exact class regardless of Stereo/AER
// cadence.
constexpr bool cinema_presentation_uses_native_asymmetric(
    const CinemaPresentationInput& input) noexcept {
    return input.packed_pair_native_asymmetric ||
        (input.sequential_aer_pair_available &&
            input.sequential_aer_pair_native_asymmetric);
}

struct PreflightInput {
    bool transport_capable{};
    bool cinema_mode{};
    bool automatic_full_vr_camera_active{};
    bool cinema_full_vr_enabled{};
    bool force_mono_cinema{};
};

constexpr bool preflight_ready(const PreflightInput& input) noexcept {
    const bool automatic_full_vr =
        input.cinema_mode &&
        input.automatic_full_vr_camera_active &&
        input.cinema_full_vr_enabled &&
        !input.force_mono_cinema;
    return input.transport_capable &&
        (!input.cinema_mode || automatic_full_vr);
}

}  // namespace w3vr::native_asymmetric_transport_policy
