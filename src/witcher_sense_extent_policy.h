#pragma once

#include <cstdint>

namespace w3vr::witcher_sense {

constexpr bool compositor_extent_matches(
    std::uint64_t t0_width,
    std::uint64_t t0_height,
    std::uint64_t t3_width,
    std::uint64_t t3_height) {
    return t0_width != 0 && t0_height != 0 &&
        t0_width == t3_width && t0_height == t3_height;
}

}  // namespace w3vr::witcher_sense
