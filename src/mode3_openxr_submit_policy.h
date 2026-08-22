#pragma once

#include <cstdint>

namespace w3vr::mode3_openxr_submit_policy {

enum class PresentationRoute : uint8_t {
    Aer,
    Stereo,
};

enum class TemporalBackend : uint8_t {
    None,
    Taau,
    Dlss,
};

enum class Projection : uint8_t {
    Symmetric,
    Asymmetric,
};

enum class Transport : uint8_t {
    Inactive,
    DirectCopy,
    IdentityShader,
    Unavailable,
};

struct Rect {
    int32_t x{};
    int32_t y{};
    uint32_t width{};
    uint32_t height{};
};

struct Input {
    bool mode3_transport{};
    bool spatial_panel{};
    bool source_pair_ready{};
    uint32_t source_width{};
    uint32_t source_height{};
    uint32_t swapchain_width{};
    uint32_t swapchain_height{};
    bool copy_compatible{};
    bool identity_shader_ready{};

    // These describe the producer. They intentionally do not select a
    // different final transport: every non-panel Mode-3 route submits the
    // complete selected-resolution image with the same identity operation.
    PresentationRoute route{PresentationRoute::Aer};
    TemporalBackend backend{TemporalBackend::None};
    Projection projection{Projection::Symmetric};
    bool dlaa{};
};

struct Decision {
    bool active{};
    Transport transport{Transport::Inactive};
    Rect source_rect{};
    Rect openxr_rect{};
};

// Mode 3 has one final OpenXR handoff. AER/Stereo, No AA/TAAU/DLSS/DLAA and
// symmetric/asymmetric projection may produce different pixels and matching
// FOV metadata, but they may not crop, fit or resize those completed pixels.
// If an exact full-resolution handoff is impossible, fail closed rather than
// silently reintroducing a resample or partial imageRect.
constexpr Decision decide(const Input& input) noexcept {
    if (!input.mode3_transport || input.spatial_panel) {
        return {};
    }

    Decision result{};
    result.active = true;
    result.openxr_rect = {
        0, 0, input.swapchain_width, input.swapchain_height};
    if (!input.source_pair_ready || input.source_width == 0 ||
        input.source_height == 0 ||
        input.swapchain_width == 0 || input.swapchain_height == 0 ||
        input.source_width != input.swapchain_width ||
        input.source_height != input.swapchain_height) {
        result.transport = Transport::Unavailable;
        return result;
    }

    result.source_rect = {
        0, 0, input.source_width, input.source_height};
    result.transport = input.copy_compatible
        ? Transport::DirectCopy
        : (input.identity_shader_ready
            ? Transport::IdentityShader
            : Transport::Unavailable);
    return result;
}

constexpr bool fixed_resolution_route_active(
    bool mode3_transport) noexcept {
    return mode3_transport;
}

// SYM and ASYM use the same slider semantics at the producer: the cover
// fraction is the old 1.0 framing, so a slider equal to cover is neutral.
constexpr float presentation_fov_scale(
    float requested_scale,
    float cover_fraction) noexcept {
    const float safe_cover = cover_fraction < 0.01f
        ? 0.01f : cover_fraction;
    const float scale = requested_scale / safe_cover;
    return scale < 0.01f ? 0.01f : (scale > 2.0f ? 2.0f : scale);
}

}  // namespace w3vr::mode3_openxr_submit_policy
