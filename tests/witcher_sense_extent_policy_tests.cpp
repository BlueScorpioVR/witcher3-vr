#include "witcher_sense_extent_policy.h"

#include <cassert>

int main() {
    using w3vr::witcher_sense::compositor_extent_matches;

    // Validated V1499 extent and the current DLSS-aligned runtime extent.
    assert(compositor_extent_matches(
        3072, 3264, 3072, 3264, 3072, 3264));
    assert(compositor_extent_matches(
        3072, 3200, 3072, 3200, 3072, 3216));

    // The policy follows the requested resolution; it does not whitelist one.
    assert(compositor_extent_matches(
        2464, 2736, 2464, 2736, 2464, 2736));
    assert(compositor_extent_matches(
        2440, 2713, 2440, 2713, 2464, 2736));

    // Paired inputs, a bounded alignment trim and non-zero extents are strict.
    assert(!compositor_extent_matches(
        3072, 3200, 3072, 3216, 3072, 3216));
    assert(!compositor_extent_matches(
        3072, 3184, 3072, 3184, 3072, 3216));
    assert(!compositor_extent_matches(
        3072, 3232, 3072, 3232, 3072, 3216));
    assert(!compositor_extent_matches(
        0, 3200, 0, 3200, 3072, 3216));
}
