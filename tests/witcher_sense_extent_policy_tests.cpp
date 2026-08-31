#include "witcher_sense_extent_policy.h"

#include <cassert>

int main() {
    using w3vr::witcher_sense::compositor_extent_matches;

    // The exact draw's paired descriptors own their real compositor extent.
    assert(compositor_extent_matches(
        3072, 3264, 3072, 3264));
    assert(compositor_extent_matches(
        3072, 3200, 3072, 3200));
    assert(compositor_extent_matches(
        3956, 4204, 3956, 4204));

    // Resolution is not whitelisted and no separately published live extent
    // participates in admission.
    assert(compositor_extent_matches(
        2464, 2736, 2464, 2736));
    assert(compositor_extent_matches(
        3904, 4160, 3904, 4160));

    // Paired and non-zero descriptor extents remain strict.
    assert(!compositor_extent_matches(
        3072, 3200, 3072, 3216));
    assert(!compositor_extent_matches(
        0, 3200, 0, 3200));
    assert(!compositor_extent_matches(
        3072, 0, 3072, 0));
    assert(!compositor_extent_matches(
        3072, 3200, 0, 3200));
}
