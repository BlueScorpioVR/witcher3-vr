#include "foliage_hmd_base_policy.h"

#include <array>
#include <cassert>
#include <cmath>
#include <limits>

namespace {

bool close(float lhs, float rhs) {
    return std::fabs(lhs - rhs) < 1.0e-5f;
}

}  // namespace

int main() {
    using namespace w3vr::foliage_hmd_base;

    static_assert(shader_pair_is_owner(
        kDistantTreesVsHash, kDistantTreesPsHash));
    static_assert(shader_pair_is_owner(kNearFrondsVsHash, kNearFrondsPsHash));
    static_assert(!shader_pair_is_owner(
        kDistantTreesVsHash, kNearFrondsPsHash));
    static_assert(is_owner(
        kNearFrondsVsHash, kNearFrondsPsHash,
        false, false, false, true, true));
    static_assert(!is_owner(
        kNearFrondsVsHash, kNearFrondsPsHash,
        false, false, true, true, true));
    static_assert(route_active(true, true));
    static_assert(!route_active(true, false));

    const std::array<float, 9> identity{
        1.0f, 0.0f, 0.0f,
        0.0f, 1.0f, 0.0f,
        0.0f, 0.0f, 1.0f};
    // Corrected camera is yawed +90 degrees from the base camera.
    const std::array<float, 9> corrected{
        0.0f, 0.0f, -1.0f,
        0.0f, 1.0f, 0.0f,
        1.0f, 0.0f, 0.0f};

    std::array<float, 128> b0{};
    for (size_t index = 0; index < b0.size(); ++index) {
        b0[index] = static_cast<float>(index) + 0.25f;
    }
    b0[12 * 4 + 1] = 1.0f;
    b0[13 * 4 + 1] = 0.0f;
    b0[14 * 4 + 1] = 0.0f;
    b0[12 * 4 + 2] = 0.0f;
    b0[13 * 4 + 2] = 1.0f;
    b0[14 * 4 + 2] = 0.0f;
    b0[17 * 4 + 0] = 0.0f;
    b0[17 * 4 + 1] = 0.0f;
    b0[17 * 4 + 2] = 1.0f;
    const auto original = b0;

    assert(compensate_b0_orientation(
        b0.data(), b0.size(), identity, corrected));
    const std::array<size_t, 9> changed{
        12 * 4 + 1, 13 * 4 + 1, 14 * 4 + 1,
        12 * 4 + 2, 13 * 4 + 2, 14 * 4 + 2,
        17 * 4 + 0, 17 * 4 + 1, 17 * 4 + 2};
    for (size_t index = 0; index < b0.size(); ++index) {
        bool is_changed{};
        for (const size_t target : changed) {
            is_changed |= index == target;
        }
        if (!is_changed) {
            assert(b0[index] == original[index]);
        }
    }

    assert(close(b0[12 * 4 + 1], 0.0f));
    assert(close(b0[13 * 4 + 1], 0.0f));
    assert(close(b0[14 * 4 + 1], 1.0f));
    assert(close(b0[12 * 4 + 2], 0.0f));
    assert(close(b0[13 * 4 + 2], 1.0f));
    assert(close(b0[14 * 4 + 2], 0.0f));
    assert(close(b0[17 * 4 + 0], -1.0f));
    assert(close(b0[17 * 4 + 1], 0.0f));
    assert(close(b0[17 * 4 + 2], 0.0f));

    std::array<float, 64> b12{};
    for (size_t index = 0; index < b12.size(); ++index) {
        b12[index] = static_cast<float>(index) + 0.75f;
    }
    b12[4 * 4 + 1] = 1.0f;
    b12[5 * 4 + 1] = 0.0f;
    b12[6 * 4 + 1] = 0.0f;
    b12[4 * 4 + 2] = 0.0f;
    b12[5 * 4 + 2] = 1.0f;
    b12[6 * 4 + 2] = 0.0f;
    b12[9 * 4 + 0] = 0.0f;
    b12[9 * 4 + 1] = 0.0f;
    b12[9 * 4 + 2] = 1.0f;
    const auto original_b12 = b12;

    assert(compensate_b12_orientation(
        b12.data(), b12.size(), identity, corrected));
    const std::array<size_t, 9> changed_b12{
        4 * 4 + 1, 5 * 4 + 1, 6 * 4 + 1,
        4 * 4 + 2, 5 * 4 + 2, 6 * 4 + 2,
        9 * 4 + 0, 9 * 4 + 1, 9 * 4 + 2};
    for (size_t index = 0; index < b12.size(); ++index) {
        bool is_changed{};
        for (const size_t target : changed_b12) {
            is_changed |= index == target;
        }
        if (!is_changed) {
            assert(b12[index] == original_b12[index]);
        }
    }
    assert(close(b12[4 * 4 + 1], 0.0f));
    assert(close(b12[5 * 4 + 1], 0.0f));
    assert(close(b12[6 * 4 + 1], 1.0f));
    assert(close(b12[4 * 4 + 2], 0.0f));
    assert(close(b12[5 * 4 + 2], 1.0f));
    assert(close(b12[6 * 4 + 2], 0.0f));
    assert(close(b12[9 * 4 + 0], -1.0f));
    assert(close(b12[9 * 4 + 1], 0.0f));
    assert(close(b12[9 * 4 + 2], 0.0f));

    auto invalid_basis = identity;
    invalid_basis[4] = std::numeric_limits<float>::quiet_NaN();
    assert(!compensate_b0_orientation(
        b0.data(), b0.size(), invalid_basis, corrected));
    assert(!compensate_b0_orientation(
        b0.data(), 18 * 4 - 1, identity, corrected));
    assert(!compensate_b12_orientation(
        b12.data(), 10 * 4 - 1, identity, corrected));
    return 0;
}
