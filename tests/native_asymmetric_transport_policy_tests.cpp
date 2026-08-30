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
    require(policy::native_temporal_proof_sufficient(false, 0x0u, 0x3u),
        "No AA must not wait for a nonexistent temporal transaction");
    require(!policy::native_temporal_proof_sufficient(true, 0x0u, 0x3u),
        "a temporal backend must fail closed without either eye proof");
    require(!policy::native_temporal_proof_sufficient(true, 0x1u, 0x3u),
        "a temporal backend must reject a half-proven pair");
    require(policy::native_temporal_proof_sufficient(true, 0x3u, 0x3u),
        "a temporal backend must accept the complete temporal pair");
    require(policy::native_temporal_proof_sufficient(true, 0x2u, 0x2u),
        "per-eye admission must accept the exact temporal eye bit");

    require(!policy::reused_camera_fallback_uses_native_asymmetric_projection(
            {false}),
        "an unconfigured asymmetric route needs no fallback override");
    require(policy::reused_camera_fallback_uses_native_asymmetric_projection(
            {true}),
        "every Mode3 cadence must complete a reused camera as native asymmetric");

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
            {false, true, false}),
        "a symmetric sequential AER pair must remain symmetric");
    require(policy::cinema_presentation_uses_native_asymmetric(
            {false, true, true}),
        "a native sequential AER pair must retain off-axis presentation");
    require(policy::cinema_presentation_uses_native_asymmetric(
            {true, false, false}),
        "the strict packed native pair must retain off-axis presentation");

    require(policy::cinema_pair_admissible(
            {false, false, false, 0x0u, 0x0u, 0x0u, false, false}),
        "a symmetric bootstrap pair does not require a native ledger");
    require(policy::cinema_pair_admissible(
            {true, true, true, 0x3u, 0x0u, 0x0u, false, false}),
        "No AA accepts a complete factory-proven native pair");
    require(!policy::cinema_pair_admissible(
            {true, true, false, 0x3u, 0x0u, 0x0u, false, false}),
        "a native pair without both frozen views must fail closed");
    require(!policy::cinema_pair_admissible(
            {true, true, true, 0x3u, 0x1u, 0x0u, true, false}),
        "TAAU requires complete temporal proof");
    require(policy::cinema_pair_admissible(
            {true, true, true, 0x3u, 0x3u, 0x0u, true, false}),
        "TAAU accepts the complete temporal pair");
    require(!policy::cinema_pair_admissible(
            {true, true, true, 0x3u, 0x3u, 0x1u, true, true}),
        "DLSS rejects an incomplete input pair");
    require(policy::cinema_pair_admissible(
            {true, true, true, 0x3u, 0x3u, 0x3u, true, true}),
        "DLSS accepts the complete input pair");

    require(!policy::preflight_ready({false, false, false, true, false}),
        "invalid transport must fail closed");
    require(policy::preflight_ready({true, false, false, true, false}),
        "gameplay keeps the established preflight route");
    require(policy::preflight_ready({true, true, true, true, false}),
        "Stereo and AER Full VR share asymmetric transport preflight");
    require(!policy::preflight_ready({true, true, false, true, false}),
        "Cinema without active Full VR camera must remain excluded");
    require(!policy::preflight_ready({true, true, true, false, false}),
        "normal Cinema must remain excluded when Full VR is disabled");
    require(!policy::preflight_ready({true, true, true, true, true}),
        "manual forced Cinema must remain excluded");

    std::cout << "native asymmetric transport policy tests passed\n";
    return 0;
}
