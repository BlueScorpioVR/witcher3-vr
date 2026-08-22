#pragma once

#include <cstdint>

namespace w3vr::smoke_visibility {

struct VisibilityCounters {
    uint64_t input_primitives{};
    uint64_t vertex_invocations{};
    uint64_t geometry_invocations{};
    uint64_t geometry_primitives{};
    uint64_t clipper_invocations{};
    uint64_t clipper_primitives{};
    uint64_t pixel_invocations{};
};

enum class VisibilityDiagnosis : uint8_t {
    Unavailable = 0,
    NoInput,
    GeometryNotInvoked,
    GeometryEmittedNothing,
    ClipOrCullRejected,
    NoPixelInvocation,
    Visible,
};

constexpr VisibilityDiagnosis diagnose_visibility(
    const VisibilityCounters& counters,
    bool gpu_ready,
    bool geometry_shader_expected) noexcept {
    if (!gpu_ready) {
        return VisibilityDiagnosis::Unavailable;
    }
    if (counters.input_primitives == 0 ||
        counters.vertex_invocations == 0) {
        return VisibilityDiagnosis::NoInput;
    }
    if (geometry_shader_expected &&
        counters.geometry_invocations == 0) {
        return VisibilityDiagnosis::GeometryNotInvoked;
    }
    if (geometry_shader_expected &&
        counters.geometry_primitives == 0) {
        return VisibilityDiagnosis::GeometryEmittedNothing;
    }
    if (counters.clipper_invocations == 0 ||
        counters.clipper_primitives == 0) {
        return VisibilityDiagnosis::ClipOrCullRejected;
    }
    if (counters.pixel_invocations == 0) {
        return VisibilityDiagnosis::NoPixelInvocation;
    }
    return VisibilityDiagnosis::Visible;
}

constexpr const char* visibility_diagnosis_name(
    VisibilityDiagnosis diagnosis) noexcept {
    switch (diagnosis) {
    case VisibilityDiagnosis::Unavailable: return "unavailable";
    case VisibilityDiagnosis::NoInput: return "no_input";
    case VisibilityDiagnosis::GeometryNotInvoked: return "gs_not_invoked";
    case VisibilityDiagnosis::GeometryEmittedNothing: return "gs_emitted_zero";
    case VisibilityDiagnosis::ClipOrCullRejected: return "clip_or_cull_zero";
    case VisibilityDiagnosis::NoPixelInvocation: return "pixel_zero";
    case VisibilityDiagnosis::Visible: return "visible";
    }
    return "unknown";
}

}  // namespace w3vr::smoke_visibility
