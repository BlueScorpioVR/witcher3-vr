#include "mode3_openxr_submit_policy.h"

#include <cmath>
#include <cstdlib>
#include <iostream>

namespace policy = w3vr::mode3_openxr_submit_policy;

namespace {

void require(bool condition, const char* message) {
    if (!condition) {
        std::cerr << message << '\n';
        std::exit(1);
    }
}

void require_full_identity(const policy::Decision& decision) {
    require(decision.active, "Mode-3 gameplay submit must be active");
    require(decision.transport == policy::Transport::DirectCopy,
        "copy-compatible Mode-3 submit must use direct copy");
    require(decision.source_rect.x == 0 && decision.source_rect.y == 0 &&
        decision.source_rect.width == 3072 &&
        decision.source_rect.height == 3264,
        "Mode-3 source rectangle must be the complete source");
    require(decision.openxr_rect.x == 0 && decision.openxr_rect.y == 0 &&
        decision.openxr_rect.width == 3072 &&
        decision.openxr_rect.height == 3264,
        "Mode-3 OpenXR imageRect must be the complete swapchain slice");
}

}  // namespace

int main() {
    const policy::PresentationRoute routes[]{
        policy::PresentationRoute::Aer,
        policy::PresentationRoute::Stereo};
    const policy::TemporalBackend backends[]{
        policy::TemporalBackend::None,
        policy::TemporalBackend::Taau,
        policy::TemporalBackend::Dlss};
    const policy::Projection projections[]{
        policy::Projection::Symmetric,
        policy::Projection::Asymmetric};

    for (const auto route : routes) {
        for (const auto backend : backends) {
            for (const auto projection : projections) {
                const bool dlaa_variants =
                    backend == policy::TemporalBackend::Dlss;
                for (int dlaa = 0; dlaa <= (dlaa_variants ? 1 : 0); ++dlaa) {
                    require_full_identity(policy::decide({
                        true, false, true,
                        3072, 3264, 3072, 3264,
                        true, true,
                        route, backend, projection, dlaa != 0}));
                }
            }
        }
    }

    const auto shader = policy::decide({
        true, false, true,
        3072, 3264, 3072, 3264,
        false, true,
        policy::PresentationRoute::Stereo,
        policy::TemporalBackend::Dlss,
        policy::Projection::Asymmetric,
        true});
    require(shader.transport == policy::Transport::IdentityShader,
        "format fallback must remain a full-rect identity shader");
    require(shader.source_rect.width == shader.openxr_rect.width &&
        shader.source_rect.height == shader.openxr_rect.height,
        "identity shader fallback must not resize");

    const auto mismatched_extent = policy::decide({
        true, false, true,
        2458, 2611, 3072, 3264,
        true, true});
    require(mismatched_extent.transport == policy::Transport::Unavailable,
        "Mode 3 must fail closed instead of fitting/cropping a partial source");
    require(mismatched_extent.openxr_rect.width == 3072 &&
        mismatched_extent.openxr_rect.height == 3264,
        "an invalid Mode-3 source must still submit a full black imageRect");

    const auto panel = policy::decide({
        true, true, true,
        3072, 3264, 3072, 3264,
        true, true});
    require(!panel.active && panel.transport == policy::Transport::Inactive,
        "world-locked panels remain outside the Mode-3 gameplay handoff");

    require(policy::fixed_resolution_route_active(true),
        "Mode 3 must keep the selected source resolution");
    require(!policy::fixed_resolution_route_active(false),
        "non-Mode-3 routes must remain outside this policy");

    const float sym_asym_scale =
        policy::presentation_fov_scale(0.8f, 0.804821f);
    require(std::fabs(sym_asym_scale - 0.994010f) < 0.00001f,
        "SYM and ASYM must share cover-normalized slider zoom");

    std::cout << "Mode-3 OpenXR submit policy tests passed\n";
    return 0;
}
