#include "hmd_camera_orientation.h"

#include <cmath>
#include <cstdio>
#include <limits>

namespace orientation = w3vr::hmd_camera_orientation;
namespace geometry = w3vr::openxr_eye_geometry;

namespace {
int failures{};
bool near(float left, float right, float tolerance = 1.0e-4f) {
    return std::fabs(left - right) <= tolerance;
}
void require(bool condition, const char* message) {
    if (!condition) {
        std::fprintf(stderr, "FAIL: %s\n", message);
        ++failures;
    }
}
}

int main() {
    orientation::EulerDegrees output{};
    require(orientation::compose_game_camera_with_local_hmd(
        {}, {-5.0f, 10.0f, 20.0f}, output), "identity compose");
    require(near(output.roll, -5.0f) && near(output.pitch, 10.0f) &&
        near(output.yaw, 20.0f), "identity preserves HMD orientation");

    const orientation::EulerDegrees game{0.0f, 35.0f, 10.0f};
    orientation::EulerDegrees left{}, right{};
    require(orientation::compose_game_camera_with_local_hmd(
        game, {0.0f, 0.0f, -40.0f}, left), "left yaw compose");
    require(orientation::compose_game_camera_with_local_hmd(
        game, {0.0f, 0.0f, 40.0f}, right), "right yaw compose");
    require(!near(left.pitch, game.pitch) || !near(left.roll, game.roll),
        "pitched left yaw is coupled");
    require(!near(right.pitch, game.pitch) || !near(right.roll, game.roll),
        "pitched right yaw is coupled");

    const orientation::EulerDegrees mixed_game{7.0f, -28.0f, 63.0f};
    const orientation::EulerDegrees mixed_hmd{-4.0f, 12.0f, 19.0f};
    require(orientation::compose_game_camera_with_local_hmd(
        mixed_game, mixed_hmd, output), "mixed compose");
    const auto expected = geometry::multiply(
        geometry::from_redengine_view_euler_degrees(
            mixed_game.roll, mixed_game.pitch, mixed_game.yaw),
        geometry::from_redengine_view_euler_degrees(
            mixed_hmd.roll, mixed_hmd.pitch, mixed_hmd.yaw));
    const auto actual = geometry::from_redengine_view_euler_degrees(
        output.roll, output.pitch, output.yaw);
    const float dot = std::fabs(expected.x * actual.x +
        expected.y * actual.y + expected.z * actual.z + expected.w * actual.w);
    require(near(dot, 1.0f), "quaternion composition preserved");

    output = {1.0f, 2.0f, 3.0f};
    const float nan = std::numeric_limits<float>::quiet_NaN();
    require(!orientation::compose_game_camera_with_local_hmd(
        {0.0f, nan, 0.0f}, {}, output), "non-finite rejected");
    require(near(output.roll, 1.0f) && near(output.pitch, 2.0f) &&
        near(output.yaw, 3.0f), "failed compose does not publish");

    float pitch{};
    require(orientation::recentered_pitch_degrees(27.0f, 27.0f, pitch) &&
        near(pitch, 0.0f), "positive pitch recenter");
    require(orientation::recentered_pitch_degrees(2.0f, 358.0f, pitch) &&
        near(pitch, 4.0f), "wrapped pitch recenter");
    return failures == 0 ? 0 : 1;
}
