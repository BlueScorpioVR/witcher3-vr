#include "smoke_visibility_policy.h"

#include <cstdlib>

namespace {

void require(bool condition) {
    if (!condition) std::abort();
}

}  // namespace

int main() {
    using namespace w3vr::smoke_visibility;

    VisibilityCounters counters{2, 6, 2, 2, 2, 2, 100};
    require(diagnose_visibility(counters, false, true) ==
        VisibilityDiagnosis::Unavailable);
    counters.input_primitives = 0;
    require(diagnose_visibility(counters, true, true) ==
        VisibilityDiagnosis::NoInput);
    counters = {2, 6, 0, 0, 0, 0, 0};
    require(diagnose_visibility(counters, true, true) ==
        VisibilityDiagnosis::GeometryNotInvoked);
    counters = {2, 6, 2, 0, 0, 0, 0};
    require(diagnose_visibility(counters, true, true) ==
        VisibilityDiagnosis::GeometryEmittedNothing);
    counters = {2, 6, 2, 2, 2, 0, 0};
    require(diagnose_visibility(counters, true, true) ==
        VisibilityDiagnosis::ClipOrCullRejected);
    counters = {2, 6, 2, 2, 2, 2, 0};
    require(diagnose_visibility(counters, true, true) ==
        VisibilityDiagnosis::NoPixelInvocation);
    counters.pixel_invocations = 100;
    require(diagnose_visibility(counters, true, true) ==
        VisibilityDiagnosis::Visible);

    // An original fallback has no GS and must still classify from clipper/PS.
    counters = {2, 6, 0, 0, 2, 2, 50};
    require(diagnose_visibility(counters, true, false) ==
        VisibilityDiagnosis::Visible);
    return 0;
}
