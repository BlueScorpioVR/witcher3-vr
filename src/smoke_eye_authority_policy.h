#pragma once

#include <algorithm>
#include <array>
#include <cmath>
#include <cstdint>

namespace w3vr::smoke_eye_authority {

inline bool prefer_closest_coherent_pair(
    uint64_t candidate_pair,
    const std::array<float, 2>& candidate_squared_distances,
    uint64_t selected_pair,
    const std::array<float, 2>& selected_squared_distances) {
    if (candidate_pair == 0 || candidate_pair == UINT64_MAX) {
        return false;
    }

    const float candidate_distance = std::min(
        candidate_squared_distances[0], candidate_squared_distances[1]);
    if (!std::isfinite(candidate_distance)) {
        return false;
    }

    if (selected_pair == 0 || selected_pair == UINT64_MAX) {
        return true;
    }

    const float selected_distance = std::min(
        selected_squared_distances[0], selected_squared_distances[1]);
    if (!std::isfinite(selected_distance)) {
        return true;
    }

    if (candidate_distance != selected_distance) {
        return candidate_distance < selected_distance;
    }
    return candidate_pair > selected_pair;
}

inline bool paired_camera_match_passes_guards(
    const std::array<float, 2>& squared_distances,
    uint32_t eye,
    float maximum_squared_distance,
    float minimum_separation_margin) {
    if (eye > 1 || !std::isfinite(maximum_squared_distance) ||
        !std::isfinite(minimum_separation_margin) ||
        maximum_squared_distance < 0.0f ||
        minimum_separation_margin < 0.0f) {
        return false;
    }

    const float selected_distance = squared_distances[eye];
    const float other_distance = squared_distances[eye ^ 1u];
    if (!std::isfinite(selected_distance) ||
        !std::isfinite(other_distance) || selected_distance < 0.0f ||
        other_distance < 0.0f ||
        selected_distance > maximum_squared_distance) {
        return false;
    }

    const float separation_margin = other_distance - selected_distance;
    // A bit-exact camera-position match is stronger eye identity than the
    // generic separation guard. Keep fail-closed behavior when both eye
    // positions are identical, because then the eye remains ambiguous.
    if (selected_distance == 0.0f && separation_margin > 0.0f) {
        return true;
    }
    return separation_margin >= minimum_separation_margin;
}

}  // namespace w3vr::smoke_eye_authority
