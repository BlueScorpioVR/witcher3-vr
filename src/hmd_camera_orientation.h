#pragma once

#include <cmath>
#include <initializer_list>

#include "openxr_eye_geometry.h"

namespace w3vr::hmd_camera_orientation {

struct EulerDegrees {
    float roll{};
    float pitch{};
    float yaw{};
};

inline bool recentered_pitch_degrees(
    float pitch,
    float reference_pitch,
    float& recentered_pitch) {
    if (!std::isfinite(pitch) || !std::isfinite(reference_pitch)) {
        return false;
    }
    const float candidate = std::remainder(pitch - reference_pitch, 360.0f);
    if (!std::isfinite(candidate)) {
        return false;
    }
    recentered_pitch = candidate;
    return true;
}

inline bool compose_game_camera_with_local_hmd(
    const EulerDegrees& game,
    const EulerDegrees& hmd,
    EulerDegrees& output) {
    for (const float value : {
            game.roll, game.pitch, game.yaw,
            hmd.roll, hmd.pitch, hmd.yaw}) {
        if (!std::isfinite(value)) {
            return false;
        }
    }

    const auto game_orientation =
        w3vr::openxr_eye_geometry::from_redengine_view_euler_degrees(
            game.roll, game.pitch, game.yaw);
    const auto hmd_orientation =
        w3vr::openxr_eye_geometry::from_redengine_view_euler_degrees(
            hmd.roll, hmd.pitch, hmd.yaw);
    XrQuaternionf composed{};
    if (!w3vr::openxr_eye_geometry::normalize(
            w3vr::openxr_eye_geometry::multiply(
                game_orientation, hmd_orientation),
            composed)) {
        return false;
    }
    const auto euler =
        w3vr::openxr_eye_geometry::to_redengine_view_euler_degrees(composed);
    if (!std::isfinite(euler.roll) || !std::isfinite(euler.pitch) ||
        !std::isfinite(euler.yaw)) {
        return false;
    }
    EulerDegrees candidate{
        w3vr::openxr_eye_geometry::nearest_equivalent_degrees(
            euler.roll, game.roll + hmd.roll),
        w3vr::openxr_eye_geometry::nearest_equivalent_degrees(
            euler.pitch, game.pitch + hmd.pitch),
        w3vr::openxr_eye_geometry::nearest_equivalent_degrees(
            euler.yaw, game.yaw + hmd.yaw)};
    if (!std::isfinite(candidate.roll) || !std::isfinite(candidate.pitch) ||
        !std::isfinite(candidate.yaw)) {
        return false;
    }
    output = candidate;
    return true;
}

}  // namespace w3vr::hmd_camera_orientation
