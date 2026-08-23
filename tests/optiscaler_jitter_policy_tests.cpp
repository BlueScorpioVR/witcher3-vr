#include "optiscaler_jitter_policy.h"

#include <cassert>
#include <cmath>
#include <limits>

namespace {

bool close(float left, float right) {
    return std::fabs(left - right) <= 0.0001f;
}

}  // namespace

int main() {
    using w3vr::optiscaler_jitter::Source;
    using w3vr::optiscaler_jitter::normalize;

    const auto expected = normalize(
        -186.601562f, -157.328430f,
        -186.249710f, 157.640930f,
        true, 186.249710f, 157.640930f);
    assert(expected.valid);
    assert(expected.source == Source::ExpectedCenter);
    assert(close(expected.x, -0.351852f));
    assert(close(expected.y, 0.312500f));

    const auto pure = normalize(
        0.25f, -0.375f,
        -186.249710f, 157.640930f,
        true, 186.249710f, 157.640930f);
    assert(pure.valid);
    assert(pure.source == Source::Pure);
    assert(close(pure.x, 0.25f));
    assert(close(pure.y, -0.375f));

    const auto native_unchanged = normalize(
        186.453415f, -157.953430f,
        -186.249710f, 157.640930f,
        false, 186.249710f, 157.640930f);
    assert(!native_unchanged.valid);
    assert(native_unchanged.source == Source::Invalid);

    const auto optiscaler_fallback = normalize(
        186.453415f, -157.953430f,
        -186.249710f, 157.640930f,
        true, 186.249710f, 157.640930f);
    assert(optiscaler_fallback.valid);
    assert(optiscaler_fallback.source == Source::PeerCenter);
    assert(close(optiscaler_fallback.x, 0.203705f));
    assert(close(optiscaler_fallback.y, -0.312500f));
    assert(close(optiscaler_fallback.applied_center_x, 186.249710f));

    const auto unrelated = normalize(
        42.0f, 73.0f,
        -186.249710f, 157.640930f,
        true, 186.249710f, 157.640930f);
    assert(!unrelated.valid);

    const auto non_finite = normalize(
        std::numeric_limits<float>::infinity(), 0.0f,
        -186.249710f, 157.640930f,
        true, 186.249710f, 157.640930f);
    assert(!non_finite.valid);
}
