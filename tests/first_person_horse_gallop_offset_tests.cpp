#include "first_person_horse_gallop_offset.h"

#include <cmath>
#include <cstdio>
#include <limits>

namespace first_person = w3vr::first_person;

int main() {
    int failures{};
    const auto require = [&](bool condition, const char* message) {
        if (!condition) {
            std::fprintf(stderr, "FAIL: %s\n", message);
            ++failures;
        }
    };
    float gallop_z = 1.42f;
    require(first_person::apply_horse_gallop_world_up_offset(
        true, first_person::kHorseGallopWorldUpOffsetMeters, gallop_z),
        "gallop applies offset");
    require(std::fabs(gallop_z - 1.72f) <= 1.0e-6f,
        "gallop adds exactly 30 cm");
    float trot_z = 1.42f;
    require(!first_person::apply_horse_gallop_world_up_offset(
        false, first_person::kHorseGallopWorldUpOffsetMeters, trot_z),
        "non-gallop does not claim offset");
    require(std::fabs(trot_z - 1.42f) <= 1.0e-6f,
        "non-gallop remains unchanged");
    const float nan = std::numeric_limits<float>::quiet_NaN();
    require(!first_person::apply_horse_gallop_world_up_offset(
        true, nan, trot_z), "invalid offset rejected");
    return failures == 0 ? 0 : 1;
}
