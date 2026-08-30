#include "world_detail_range_policy.h"

#ifdef NDEBUG
#undef NDEBUG
#endif
#include <cassert>
#include <cmath>
#include <limits>

namespace {

bool near(float lhs, float rhs, float tolerance = 0.0001f) {
    return std::fabs(lhs - rhs) <= tolerance;
}

} // namespace

int main() {
    using namespace w3vr::render_proxy_distance;

    constexpr float native_scale = 1.0f;
    constexpr float widened_vr_scale = 6.1188f;

    assert(near(clamp_world_detail_range(1.25f), 1.0f));
    assert(near(clamp_world_detail_range(0.25f), 0.40f));
    assert(near(clamp_world_detail_range(
        std::numeric_limits<float>::quiet_NaN()), 1.0f));

    assert(near(select_target_distance_scale(
        native_scale, widened_vr_scale, 1.0f), 1.0f));
    assert(near(select_target_distance_scale(
        native_scale, widened_vr_scale, 0.75f), 1.7777778f));
    assert(near(select_target_distance_scale(
        native_scale, widened_vr_scale, 0.50f), 4.0f));
    assert(near(select_target_distance_scale(
        native_scale, widened_vr_scale, 0.40f), widened_vr_scale));

    // A narrower headset can reach its original engine result before the
    // slider floor. Never exceed that untouched widened-FOV scale.
    assert(near(select_target_distance_scale(
        native_scale, 2.25f, 0.50f), 2.25f));

    assert(near(select_target_raw_distance_scale(
        0.75f, 1.0f, 1.0f, widened_vr_scale), 0.75f));
    assert(near(select_target_raw_distance_scale(
        0.75f, 1.0f, 4.0f, widened_vr_scale), 4.0f));
    assert(near(select_target_raw_distance_scale(
        0.75f, 1.0f, 8.0f, widened_vr_scale), widened_vr_scale));

    return 0;
}
