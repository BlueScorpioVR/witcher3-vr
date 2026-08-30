#pragma once

#include <algorithm>
#include <cmath>

namespace w3vr::render_proxy_distance {

constexpr float kMinimumWorldDetailRange = 0.40f;
constexpr float kMaximumWorldDetailRange = 1.00f;

inline float clamp_world_detail_range(float requested_range) {
    if (!std::isfinite(requested_range)) {
        return kMaximumWorldDetailRange;
    }
    return std::clamp(requested_range,
        kMinimumWorldDetailRange, kMaximumWorldDetailRange);
}

// REDengine compares squared camera distance after multiplying it by the
// render-proxy scale. A requested linear range fraction therefore maps to the
// inverse square. Clamp between the accepted native-FOV correction and the
// untouched widened-VR-FOV value: this control can neither extend visibility
// beyond V1122 nor cull more aggressively than the original engine result.
inline float select_target_distance_scale(float native_scale,
    float original_visible_scale, float requested_range) {
    if (!std::isfinite(native_scale) || native_scale <= 0.0f ||
        !std::isfinite(original_visible_scale) ||
        original_visible_scale < native_scale) {
        return original_visible_scale;
    }

    const float range = clamp_world_detail_range(requested_range);
    const float target = native_scale / (range * range);
    if (!std::isfinite(target)) {
        return original_visible_scale;
    }
    return std::clamp(target, native_scale, original_visible_scale);
}

inline float select_target_raw_distance_scale(float native_raw_scale,
    float native_scale, float target_scale, float original_visible_raw_scale) {
    if (!std::isfinite(native_raw_scale) || native_raw_scale <= 0.0f ||
        !std::isfinite(native_scale) || native_scale <= 0.0f ||
        !std::isfinite(target_scale) || target_scale <= 0.0f ||
        !std::isfinite(original_visible_raw_scale) ||
        original_visible_raw_scale <= 0.0f) {
        return original_visible_raw_scale;
    }

    if (target_scale <= native_scale) {
        return native_raw_scale;
    }
    return std::clamp(
        target_scale, native_raw_scale, original_visible_raw_scale);
}

} // namespace w3vr::render_proxy_distance
