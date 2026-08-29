#include "smoke_eye_authority_policy.h"

#include <array>
#include <cassert>
#include <limits>

int main() {
    using w3vr::smoke_eye_authority::paired_camera_match_passes_guards;
    using w3vr::smoke_eye_authority::prefer_closest_coherent_pair;

    const std::array<float, 2> newest_far{0.0132f, 0.01395f};
    const std::array<float, 2> older_close{0.0001f, 0.0040f};
    assert(prefer_closest_coherent_pair(
        1020, older_close, 1024, newest_far));
    assert(!prefer_closest_coherent_pair(
        1024, newest_far, 1020, older_close));

    const std::array<float, 2> equal_a{0.0002f, 0.0030f};
    const std::array<float, 2> equal_b{0.0030f, 0.0002f};
    assert(prefer_closest_coherent_pair(41, equal_a, 40, equal_b));
    assert(!prefer_closest_coherent_pair(39, equal_a, 40, equal_b));

    const std::array<float, 2> invalid_distance{
        std::numeric_limits<float>::infinity(),
        std::numeric_limits<float>::infinity()};
    assert(!prefer_closest_coherent_pair(
        0, older_close, 1024, newest_far));
    assert(!prefer_closest_coherent_pair(
        UINT64_MAX, older_close, 1024, newest_far));
    assert(!prefer_closest_coherent_pair(
        1025, invalid_distance, 1024, newest_far));
    assert(prefer_closest_coherent_pair(
        1025, older_close, 1024, invalid_distance));

    constexpr float maximum_squared_distance = 0.0049f;
    constexpr float minimum_separation_margin = 0.0005f;
    // Exact V1421 F3 residuals: the selected eye is bit-exact while the
    // opposite eye is distinct but lies below the generic margin.
    assert(paired_camera_match_passes_guards(
        {0.0f, 0.000190970459f}, 0,
        maximum_squared_distance, minimum_separation_margin));
    assert(paired_camera_match_passes_guards(
        {0.000430600427f, 0.0f}, 1,
        maximum_squared_distance, minimum_separation_margin));

    // An identical two-eye position remains ambiguous, and a merely close
    // non-exact match still has to satisfy the unchanged generic margin.
    assert(!paired_camera_match_passes_guards(
        {0.0f, 0.0f}, 0,
        maximum_squared_distance, minimum_separation_margin));
    assert(!paired_camera_match_passes_guards(
        {0.0000001f, 0.0004f}, 0,
        maximum_squared_distance, minimum_separation_margin));
    assert(paired_camera_match_passes_guards(
        {0.0001f, 0.0007f}, 0,
        maximum_squared_distance, minimum_separation_margin));
    assert(!paired_camera_match_passes_guards(
        {0.0050f, 0.0200f}, 0,
        maximum_squared_distance, minimum_separation_margin));
    assert(!paired_camera_match_passes_guards(
        invalid_distance, 0,
        maximum_squared_distance, minimum_separation_margin));
    assert(!paired_camera_match_passes_guards(
        older_close, 2,
        maximum_squared_distance, minimum_separation_margin));

    return 0;
}
