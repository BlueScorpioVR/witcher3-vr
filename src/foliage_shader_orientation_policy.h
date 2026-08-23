#pragma once

#include <cstdint>

namespace w3vr::foliage_shader_orientation {

inline constexpr uint64_t kDistantTreesVsHash = 0x5E2E73E55B072A74ull;
inline constexpr uint64_t kDistantTreesPsHash = 0x7FC495F2BB36CAC0ull;
inline constexpr uint64_t kNearFrondsVsHash = 0xF9282625E62BCC6Aull;
inline constexpr uint64_t kNearFrondsPsHash = 0x5B6F5C6CA86B8C9Dull;

enum class Owner : uint8_t {
    None,
    DistantTrees,
    NearFronds,
};

[[nodiscard]] constexpr Owner owner_for_shader_pair(
    uint64_t vs_hash,
    uint64_t ps_hash) {
    if (vs_hash == kDistantTreesVsHash &&
        ps_hash == kDistantTreesPsHash) {
        return Owner::DistantTrees;
    }
    if (vs_hash == kNearFrondsVsHash && ps_hash == kNearFrondsPsHash) {
        return Owner::NearFronds;
    }
    return Owner::None;
}

[[nodiscard]] constexpr Owner classify_owner(
    uint64_t vs_hash,
    uint64_t ps_hash,
    bool has_hull_shader,
    bool has_domain_shader,
    bool has_geometry_shader,
    bool triangle_topology,
    bool depth_enabled) {
    const auto owner = owner_for_shader_pair(vs_hash, ps_hash);
    return owner != Owner::None && !has_hull_shader && !has_domain_shader &&
            !has_geometry_shader && triangle_topology && depth_enabled
        ? owner
        : Owner::None;
}

// The two immutable shader variants are selected for every OpenXR HMD-
// freelook route. Projection symmetry, eye cadence and AA backend are not
// inputs to this policy.
[[nodiscard]] constexpr bool route_active(
    bool openxr_enabled,
    bool hmd_freelook) {
    return openxr_enabled && hmd_freelook;
}

}  // namespace w3vr::foliage_shader_orientation
