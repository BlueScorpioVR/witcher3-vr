#pragma once

#include <cmath>

namespace w3vr::first_person {

constexpr float kHorseGallopWorldUpOffsetMeters = 0.30f;

inline bool apply_horse_gallop_world_up_offset(
    bool horse_gallop,
    float offset_meters,
    float& world_z) {
    if (!horse_gallop) {
        return false;
    }
    if (!std::isfinite(offset_meters) || !std::isfinite(world_z)) {
        return false;
    }
    const float elevated = world_z + offset_meters;
    if (!std::isfinite(elevated)) {
        return false;
    }
    world_z = elevated;
    return true;
}

}  // namespace w3vr::first_person
