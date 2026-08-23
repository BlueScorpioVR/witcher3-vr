#pragma once

#include <cmath>

namespace w3vr::optiscaler_jitter {

enum class Source : unsigned {
    Invalid = 0,
    Pure = 1,
    ExpectedCenter = 2,
    PeerCenter = 3,
};

struct NormalizedJitter {
    bool valid{};
    float x{};
    float y{};
    float applied_center_x{};
    float applied_center_y{};
    Source source{Source::Invalid};
};

inline NormalizedJitter normalize(
    float source_x,
    float source_y,
    float expected_center_x,
    float expected_center_y,
    bool allow_peer_center,
    float peer_center_x,
    float peer_center_y,
    float residual_limit = 1.0f) {
    NormalizedJitter result{};
    if (!std::isfinite(source_x) || !std::isfinite(source_y) ||
        !std::isfinite(expected_center_x) ||
        !std::isfinite(expected_center_y) ||
        !std::isfinite(residual_limit) || residual_limit < 0.0f) {
        return result;
    }

    const auto try_center = [&](float center_x, float center_y, Source source) {
        const float residual_x = source_x - center_x;
        const float residual_y = source_y + center_y;
        if (std::fabs(residual_x) > residual_limit ||
            std::fabs(residual_y) > residual_limit) {
            return false;
        }
        result.valid = true;
        result.x = residual_x;
        result.y = residual_y;
        result.applied_center_x = center_x;
        result.applied_center_y = center_y;
        result.source = source;
        return true;
    };

    if (try_center(
            expected_center_x, expected_center_y,
            Source::ExpectedCenter)) {
        return result;
    }

    if (std::fabs(source_x) <= residual_limit &&
        std::fabs(source_y) <= residual_limit) {
        result.valid = true;
        result.x = source_x;
        result.y = source_y;
        result.source = Source::Pure;
        return result;
    }

    if (allow_peer_center && std::isfinite(peer_center_x) &&
        std::isfinite(peer_center_y)) {
        try_center(peer_center_x, peer_center_y, Source::PeerCenter);
    }
    return result;
}

}  // namespace w3vr::optiscaler_jitter
