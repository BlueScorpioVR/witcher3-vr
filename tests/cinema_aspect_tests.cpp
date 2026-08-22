#include "cinema_aspect.h"

#include <cmath>
#include <cstdio>

namespace {
int failures{};
void require(bool condition, const char* message) {
    if (!condition) {
        std::fprintf(stderr, "FAIL: %s\n", message);
        ++failures;
    }
}
bool near(float left, float right) {
    return std::fabs(left - right) <= 1.0e-6f;
}
}

int main() {
    constexpr w3vr::CinemaAspect aspects[]{
        w3vr::CinemaAspect::FiveFour,
        w3vr::CinemaAspect::FourThree,
        w3vr::CinemaAspect::SixteenTen,
        w3vr::CinemaAspect::SixteenNine,
    };
    for (const auto aspect : aspects) {
        require(w3vr::ParseCinemaAspect(
            w3vr::CinemaAspectIniValue(aspect)) == aspect,
            "Cinema aspect round-trip");
    }
    require(w3vr::ParseCinemaAspect("16:10") ==
        w3vr::CinemaAspect::SixteenTen, "16:10 alias");
    require(w3vr::ParseCinemaAspect("16:9") ==
        w3vr::CinemaAspect::SixteenNine, "16:9 alias");
    require(near(w3vr::CinemaAspectRatio(
        w3vr::CinemaAspect::SixteenTen), 1.6f), "16:10 ratio");
    require(near(w3vr::CinemaAspectRatio(
        w3vr::CinemaAspect::SixteenNine), 16.0f / 9.0f), "16:9 ratio");
    require(w3vr::ParseCinemaAspect(
        "unsupported", w3vr::CinemaAspect::FourThree) ==
            w3vr::CinemaAspect::FourThree,
        "unknown aspect uses explicit fallback");
    return failures == 0 ? 0 : 1;
}
