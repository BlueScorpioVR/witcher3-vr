#pragma once

#include <cstdint>

namespace w3vr::foliage_native_snapshot {

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

[[nodiscard]] constexpr bool route_active(
    bool openxr_enabled,
    bool hmd_freelook) {
    return openxr_enabled && hmd_freelook;
}

}  // namespace w3vr::foliage_native_snapshot
