#pragma once

namespace w3vr::aer_presentation_size_policy {

struct FixedResolutionRouteInput {
    bool mode3_transport{};
};

// Every Mode-3 AER/Stereo backend owns a selected-resolution per-eye source.
// Presentation Size must therefore never resize the swapchain; it changes
// only the submitted angular FOV for No AA, TAAU and DLSS alike.
constexpr bool fixed_resolution_route_active(
    const FixedResolutionRouteInput& input) noexcept {
    return input.mode3_transport;
}

struct FinalOpenXrRemapInput {
    bool mode3_aer{};
    bool native_asymmetric{};
    bool taau_backend{};
    bool dlss_backend{};
    bool gameplay{};
    bool hmd_freelook{};
    bool projection_pipeline_ready{};
    float presentation_scale{1.0f};
};

// AER renders a symmetric envelope and publishes the two final eyes through
// AFW. Remap that completed gameplay image into the same per-eye OpenXR FOV
// policy used by strict Stereo. Both TAAU and DLSS take this route at scale 1
// so neither can fall through to the legacy cover crop; below 1 the slider
// changes only FOV. Cinema and producer work remain outside this policy.
constexpr bool final_openxr_remap_active(
    const FinalOpenXrRemapInput& input) noexcept {
    return input.mode3_aer && input.native_asymmetric && input.gameplay &&
        input.hmd_freelook && input.projection_pipeline_ready &&
        (input.taau_backend || input.dlss_backend) &&
        input.presentation_scale > 0.0f &&
        input.presentation_scale <= 1.0001f;
}

}  // namespace w3vr::aer_presentation_size_policy
