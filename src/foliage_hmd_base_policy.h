#pragma once

#include <algorithm>
#include <array>
#include <cmath>
#include <cstddef>
#include <cstdint>

namespace w3vr::foliage_hmd_base {

inline constexpr uint64_t kDistantTreesVsHash = 0x5E2E73E55B072A74ull;
inline constexpr uint64_t kDistantTreesPsHash = 0x7FC495F2BB36CAC0ull;
inline constexpr uint64_t kNearFrondsVsHash = 0xF9282625E62BCC6Aull;
inline constexpr uint64_t kNearFrondsPsHash = 0x5B6F5C6CA86B8C9Dull;

[[nodiscard]] constexpr bool shader_pair_is_owner(
    uint64_t vs_hash,
    uint64_t ps_hash) {
    return
        (vs_hash == kDistantTreesVsHash &&
            ps_hash == kDistantTreesPsHash) ||
        (vs_hash == kNearFrondsVsHash && ps_hash == kNearFrondsPsHash);
}

[[nodiscard]] constexpr bool is_owner(
    uint64_t vs_hash,
    uint64_t ps_hash,
    bool has_hull_shader,
    bool has_domain_shader,
    bool has_geometry_shader,
    bool triangle_topology,
    bool depth_enabled) {
    return shader_pair_is_owner(vs_hash, ps_hash) &&
        !has_hull_shader && !has_domain_shader && !has_geometry_shader &&
        triangle_topology && depth_enabled;
}

// The draw-local correction is independent of projection symmetry, eye
// scheduling and the active AA/upscaling backend. Keep V18017's established
// OpenXR + HMD-freelook activation contract.
[[nodiscard]] constexpr bool route_active(
    bool openxr_enabled,
    bool hmd_freelook) {
    return openxr_enabled && hmd_freelook;
}

[[nodiscard]] inline bool camera_basis_valid(
    const std::array<float, 9>& basis) {
    for (size_t axis = 0; axis < 3; ++axis) {
        float length_squared{};
        for (size_t component = 0; component < 3; ++component) {
            const float value = basis[axis * 3 + component];
            if (!std::isfinite(value)) {
                return false;
            }
            length_squared += value * value;
        }
        if (length_squared < 0.64f || length_squared > 1.44f) {
            return false;
        }
    }
    return true;
}

// Rotate a world-space direction out of the corrected/HMD camera basis and
// into REDengine's unmodified base-camera basis. Basis vectors are stored as
// consecutive right/up/forward world vectors.
[[nodiscard]] inline bool compensate_world_direction(
    const std::array<float, 9>& base_basis,
    const std::array<float, 9>& corrected_basis,
    const std::array<float, 3>& direction,
    std::array<float, 3>& compensated) {
    if (!camera_basis_valid(base_basis) ||
        !camera_basis_valid(corrected_basis)) {
        return false;
    }
    for (const float value : direction) {
        if (!std::isfinite(value)) {
            return false;
        }
    }

    std::array<float, 3> corrected_coordinates{};
    for (size_t axis = 0; axis < 3; ++axis) {
        for (size_t component = 0; component < 3; ++component) {
            corrected_coordinates[axis] +=
                corrected_basis[axis * 3 + component] *
                direction[component];
        }
    }

    compensated = {};
    for (size_t axis = 0; axis < 3; ++axis) {
        for (size_t component = 0; component < 3; ++component) {
            compensated[component] +=
                base_basis[axis * 3 + component] *
                corrected_coordinates[axis];
        }
    }
    return std::all_of(
        compensated.begin(), compensated.end(),
        [](float value) { return std::isfinite(value); });
}

// Apply the same camera-space rotation removal to the three direction vectors
// used by either half of the foliage shader's temporal contract. The current
// half lives in b0 rows 12..14/17; the previous half lives in b12 rows
// 4..6/9. Projection and camera-position values deliberately remain native.
[[nodiscard]] inline bool compensate_orientation_block(
    float* constants,
    size_t float_count,
    size_t basis_first_row,
    size_t direction_row,
    const std::array<float, 9>& base_basis,
    const std::array<float, 9>& corrected_basis) {
    if (constants == nullptr ||
        float_count < (std::max(basis_first_row + 3, direction_row + 1) * 4) ||
        !camera_basis_valid(base_basis) ||
        !camera_basis_valid(corrected_basis)) {
        return false;
    }

    const auto compensate = [&](size_t row, size_t column, bool vertical) {
        const std::array<float, 3> source{
            vertical ? constants[(row + 0) * 4 + column]
                     : constants[row * 4 + 0],
            vertical ? constants[(row + 1) * 4 + column]
                     : constants[row * 4 + 1],
            vertical ? constants[(row + 2) * 4 + column]
                     : constants[row * 4 + 2]};
        std::array<float, 3> result{};
        if (!compensate_world_direction(
                base_basis, corrected_basis, source, result)) {
            return false;
        }
        if (vertical) {
            constants[(row + 0) * 4 + column] = result[0];
            constants[(row + 1) * 4 + column] = result[1];
            constants[(row + 2) * 4 + column] = result[2];
        } else {
            constants[row * 4 + 0] = result[0];
            constants[row * 4 + 1] = result[1];
            constants[row * 4 + 2] = result[2];
        }
        return true;
    };

    return compensate(basis_first_row, 1, true) &&
        compensate(basis_first_row, 2, true) &&
        compensate(direction_row, 0, false);
}

[[nodiscard]] inline bool compensate_b0_orientation(
    float* b0,
    size_t b0_float_count,
    const std::array<float, 9>& base_basis,
    const std::array<float, 9>& corrected_basis) {
    return compensate_orientation_block(
        b0, b0_float_count, 12, 17, base_basis, corrected_basis);
}

[[nodiscard]] inline bool compensate_b12_orientation(
    float* b12,
    size_t b12_float_count,
    const std::array<float, 9>& base_basis,
    const std::array<float, 9>& corrected_basis) {
    return compensate_orientation_block(
        b12, b12_float_count, 4, 9, base_basis, corrected_basis);
}

}  // namespace w3vr::foliage_hmd_base
