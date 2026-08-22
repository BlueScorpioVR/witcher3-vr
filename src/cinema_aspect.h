#pragma once

#include <string_view>

namespace w3vr {

enum class CinemaAspect {
    FiveFour,
    FourThree,
    SixteenTen,
    SixteenNine,
    Count,
};

constexpr CinemaAspect ParseCinemaAspect(
    std::string_view value,
    CinemaAspect fallback = CinemaAspect::FiveFour) {
    if (value == "5x4" || value == "5:4") {
        return CinemaAspect::FiveFour;
    }
    if (value == "4x3" || value == "4:3") {
        return CinemaAspect::FourThree;
    }
    if (value == "16x10" || value == "16:10") {
        return CinemaAspect::SixteenTen;
    }
    if (value == "16x9" || value == "16:9") {
        return CinemaAspect::SixteenNine;
    }
    return fallback;
}

constexpr const char* CinemaAspectIniValue(CinemaAspect aspect) {
    switch (aspect) {
    case CinemaAspect::FourThree:
        return "4x3";
    case CinemaAspect::SixteenTen:
        return "16x10";
    case CinemaAspect::SixteenNine:
        return "16x9";
    case CinemaAspect::FiveFour:
    case CinemaAspect::Count:
    default:
        return "5x4";
    }
}

constexpr float CinemaAspectRatio(CinemaAspect aspect) {
    switch (aspect) {
    case CinemaAspect::FourThree:
        return 4.0f / 3.0f;
    case CinemaAspect::SixteenTen:
        return 16.0f / 10.0f;
    case CinemaAspect::SixteenNine:
        return 16.0f / 9.0f;
    case CinemaAspect::FiveFour:
    case CinemaAspect::Count:
    default:
        return 5.0f / 4.0f;
    }
}

}  // namespace w3vr
