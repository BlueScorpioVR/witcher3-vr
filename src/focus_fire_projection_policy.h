#pragma once

#include <algorithm>
#include <array>
#include <cmath>

namespace w3vr::focus_fire_projection {

struct RuntimeCenters {
    std::array<float, 2> x{};
    std::array<float, 2> y{};
};

struct EyeMatch {
    bool matched{};
    int eye{-1};
    float distance{};
};

enum class B1Contract : unsigned {
    Unknown = 0,
    Centered = 1,
    AlreadyAsymmetric = 2,
};

struct B1Classification {
    B1Contract contract{B1Contract::Unknown};
    int eye{-1};
};

inline bool valid(const RuntimeCenters& centers) noexcept {
    for (unsigned eye = 0; eye < 2; ++eye) {
        if (!std::isfinite(centers.x[eye]) ||
            !std::isfinite(centers.y[eye]) ||
            std::fabs(centers.x[eye]) > 0.5f ||
            std::fabs(centers.y[eye]) > 0.5f) {
            return false;
        }
    }
    return true;
}

inline EyeMatch match_eye(
    float center_x,
    float center_y,
    const RuntimeCenters& centers,
    float tolerance) noexcept {
    if (!valid(centers) || !std::isfinite(center_x) ||
        !std::isfinite(center_y) || !std::isfinite(tolerance) ||
        tolerance <= 0.0f) {
        return {};
    }
    const std::array<float, 2> distances{{
        std::max(std::fabs(center_x - centers.x[0]),
            std::fabs(center_y - centers.y[0])),
        std::max(std::fabs(center_x - centers.x[1]),
            std::fabs(center_y - centers.y[1]))}};
    const int eye = distances[0] <= distances[1] ? 0 : 1;
    const int other_eye = eye ^ 1;
    if (distances[eye] > tolerance) {
        return {};
    }
    // A center shared by both eyes proves the projection contract but cannot
    // identify an eye. Keep that distinction so callers can fail closed.
    const bool ambiguous = std::fabs(
        distances[eye] - distances[other_eye]) <= 1.0e-6f;
    return {true, ambiguous ? -1 : eye, distances[eye]};
}

inline B1Classification classify_b1(
    float estimated_x,
    float estimated_y,
    const RuntimeCenters& centers,
    float tolerance) noexcept {
    if (!std::isfinite(estimated_x) || !std::isfinite(estimated_y) ||
        !std::isfinite(tolerance) || tolerance <= 0.0f) {
        return {};
    }
    const float centered_distance = std::max(
        std::fabs(estimated_x), std::fabs(estimated_y));
    const bool centered_match = centered_distance <= tolerance;
    const EyeMatch asymmetric = match_eye(
        estimated_x, estimated_y, centers, tolerance);
    if (!centered_match && !asymmetric.matched) {
        return {};
    }
    if (centered_match && asymmetric.matched) {
        // Very small optical offsets can make both hypotheses pass the legacy
        // tolerance. Select only the strictly closer one; an exact tie remains
        // unknown and therefore cannot authorize a second correction.
        if (std::fabs(centered_distance - asymmetric.distance) <= 1.0e-6f) {
            return {};
        }
        if (asymmetric.distance < centered_distance) {
            return {B1Contract::AlreadyAsymmetric, asymmetric.eye};
        }
        return {B1Contract::Centered, -1};
    }
    if (asymmetric.matched) {
        return {B1Contract::AlreadyAsymmetric, asymmetric.eye};
    }
    return {B1Contract::Centered, -1};
}

} // namespace w3vr::focus_fire_projection
