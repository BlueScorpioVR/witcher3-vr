#include "native_asymmetric_transport_policy.h"

#include <cstdlib>
#include <iostream>

namespace policy = w3vr::native_asymmetric_transport_policy;

void require(bool condition, const char* message) {
    if (!condition) {
        std::cerr << "FAIL: " << message << '\n';
        std::exit(1);
    }
}

int main() {
    require(!policy::reused_camera_fallback_uses_native_asymmetric_projection(
            {false, false}),
        "an unconfigured asymmetric route needs no fallback override");
    require(policy::reused_camera_fallback_uses_native_asymmetric_projection(
            {true, false}),
        "strict Stereo must complete a reused camera as native asymmetric");
    require(!policy::reused_camera_fallback_uses_native_asymmetric_projection(
            {true, true}),
        "AER must retain its independent centered sequential fallback");

    policy::ReusedCameraEpisodeState episode{};
    require(!policy::admit_native_reused_camera_pair(
            episode, 7, 100, 50, 1),
        "one isolated fallback eye must remain centered");
    require(!policy::admit_native_reused_camera_pair(
            episode, 7, 110, 51, 1),
        "a distant one-eye fallback must start a fresh centered episode");
    require(!policy::admit_native_reused_camera_pair(
            episode, 7, 111, 51, 0),
        "the complete proof pair must keep one centered decision");
    require(policy::admit_native_reused_camera_pair(
            episode, 7, 112, 52, 1),
        "the pair after complete L/R proof may enter native projection");
    require(policy::admit_native_reused_camera_pair(
            episode, 7, 113, 52, 0),
        "both eyes of an admitted pair must keep native projection");
    require(!policy::admit_native_reused_camera_pair(
            episode, 7, 120, 53, 1),
        "a presentation gap must revoke native episode admission");
    require(!policy::admit_native_reused_camera_pair(
            episode, 8, 121, 54, 1),
        "a renderer generation change must revoke admission");
    policy::reset_reused_camera_episode(episode, 8);
    require(!episode.initialized && !episode.native_armed,
        "an explicit factory reset must clear the episode proof");

    require(!policy::stereo_frame_fallback_admissible(
            {false, true, false}),
        "an untagged frame cannot own the stereo fallback");
    require(policy::stereo_frame_fallback_admissible(
            {true, true, false}),
        "a stereo route must repair a reused camera when the factory is stale");
    require(!policy::stereo_frame_fallback_admissible(
            {true, true, true}),
        "a native asymmetric route must not rewrite an ordinary factory camera");
    require(policy::stereo_frame_fallback_admissible(
            {true, false, true}),
        "a symmetric route keeps its established internal fallback proof");

    require(!policy::cinema_presentation_uses_native_asymmetric(
            {false, true}),
        "a sequential AER Cinema pair must retain symmetric presentation");
    require(policy::cinema_presentation_uses_native_asymmetric(
            {true, false}),
        "the strict packed native pair must retain off-axis presentation");

    require(!policy::preflight_ready({false, false, false, true, false}),
        "invalid transport must fail closed");
    require(policy::preflight_ready({true, false, false, true, false}),
        "gameplay keeps the established preflight route");
    require(policy::preflight_ready({true, false, false, true, false, true}),
        "AER gameplay may bootstrap native asymmetric transport");
    require(policy::preflight_ready({true, true, true, true, false}),
        "strict Stereo Full VR may bootstrap asymmetric transport");
    require(!policy::preflight_ready({true, true, true, true, false, true}),
        "AER Full VR must retain V1242 symmetric Cinema preflight");
    require(!policy::preflight_ready({true, true, false, true, false}),
        "Cinema without active Full VR camera must remain excluded");
    require(!policy::preflight_ready({true, true, true, false, false}),
        "normal Cinema must remain excluded when Full VR is disabled");
    require(!policy::preflight_ready({true, true, true, true, true}),
        "manual forced Cinema must remain excluded");

    std::cout << "native asymmetric transport policy tests passed\n";
    return 0;
}
