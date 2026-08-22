#include "aer_presentation_size_policy.h"

#include <cstdlib>
#include <iostream>

namespace policy = w3vr::aer_presentation_size_policy;

namespace {

void require(bool condition, const char* message) {
    if (!condition) {
        std::cerr << message << '\n';
        std::exit(1);
    }
}

}  // namespace

int main() {
    const policy::FinalOpenXrRemapInput active{
        true, true, false, true, true, true, true, 0.75f};
    require(policy::final_openxr_remap_active(active),
        "AER asymmetric gameplay below scale 1 must use the final OpenXR remap");

    auto input = active;
    input.mode3_aer = false;
    require(!policy::final_openxr_remap_active(input),
        "strict Stereo must keep its existing native presentation");
    input = active;
    input.native_asymmetric = false;
    require(!policy::final_openxr_remap_active(input),
        "AER symmetric projection must remain unchanged");
    input = active;
    input.gameplay = false;
    require(!policy::final_openxr_remap_active(input),
        "Cinema and loading presentation must remain unchanged");
    input = active;
    input.projection_pipeline_ready = false;
    require(!policy::final_openxr_remap_active(input),
        "the remap must fail closed without the final projection pipeline");
    input = active;
    input.presentation_scale = 1.0f;
    require(policy::final_openxr_remap_active(input),
        "AER DLSS scale 1 must bypass the legacy cover crop");

    input = active;
    input.taau_backend = true;
    input.dlss_backend = false;
    input.presentation_scale = 1.0f;
    require(policy::final_openxr_remap_active(input),
        "AER TAAU scale 1 must bypass the legacy cover crop");

    input.taau_backend = false;
    require(!policy::final_openxr_remap_active(input),
        "AER without TAAU or DLSS must not enter the temporal remap");

    const policy::FixedResolutionRouteInput mode3_route{true};
    require(policy::fixed_resolution_route_active(mode3_route),
        "every Mode-3 AER/Stereo backend must keep source resolution");
    auto route = mode3_route;
    route.mode3_transport = false;
    require(!policy::fixed_resolution_route_active(route),
        "the Mode-3 resolution policy must not change non-Mode-3 routes");

    std::cout << "AER presentation size policy tests passed\n";
    return 0;
}
