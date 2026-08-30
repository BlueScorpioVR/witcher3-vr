#pragma once

#include <cstdint>

namespace w3vr::witcher_sense {

// DLSS may align an internal output dimension down to a 32-pixel boundary.
// The largest valid trim produced by that alignment is therefore 31 pixels.
inline constexpr std::uint64_t kMaximumAlignmentTrim = 31;

constexpr bool requested_extent_component_matches(
    std::uint64_t actual,
    std::uint64_t requested) {
    return actual != 0 && requested != 0 && actual <= requested &&
        requested - actual <= kMaximumAlignmentTrim;
}

constexpr bool compositor_extent_matches(
    std::uint64_t t0_width,
    std::uint64_t t0_height,
    std::uint64_t t3_width,
    std::uint64_t t3_height,
    std::uint64_t requested_width,
    std::uint64_t requested_height) {
    return t0_width == t3_width && t0_height == t3_height &&
        requested_extent_component_matches(t0_width, requested_width) &&
        requested_extent_component_matches(t0_height, requested_height);
}

}  // namespace w3vr::witcher_sense
