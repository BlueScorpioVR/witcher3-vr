#include "focus_fire_projection_policy.h"

#include <cmath>
#include <cstdlib>
#include <iostream>

namespace policy = w3vr::focus_fire_projection;

namespace {

void require(bool condition, const char* message) {
    if (!condition) {
        std::cerr << "FAILED: " << message << '\n';
        std::exit(1);
    }
}

void test_quest_centers() {
    const policy::RuntimeCenters centers{{
        0.242512643f, -0.242512643f}, {
        0.193187416f, 0.193187416f}};
    require(policy::valid(centers), "Quest centers valid");
    require(policy::match_eye(
        0.242512643f, 0.193187416f, centers, 0.06f).eye == 0,
        "Quest eye 0 match");
    require(policy::match_eye(
        -0.242512643f, 0.193187416f, centers, 0.06f).eye == 1,
        "Quest eye 1 match");
    require(policy::classify_b1(0.0f, 0.0f, centers, 0.06f).contract ==
            policy::B1Contract::Centered,
        "Quest centered b1 needs one correction");
    const auto corrected = policy::classify_b1(
        0.242512643f, 0.193187416f, centers, 0.06f);
    require(corrected.contract == policy::B1Contract::AlreadyAsymmetric &&
            corrected.eye == 0,
        "Quest corrected b1 rejects a second correction");
}

void test_pimax_dream_air_centers() {
    const policy::RuntimeCenters centers{{
        0.210230261f, -0.210230276f}, {0.0f, 0.0f}};
    require(policy::valid(centers), "Pimax centers valid");
    require(policy::match_eye(
        0.210230261f, 0.0f, centers, 0.06f).eye == 0,
        "Pimax eye 0 match");
    require(policy::match_eye(
        -0.210230276f, 0.0f, centers, 0.06f).eye == 1,
        "Pimax eye 1 match");
    require(policy::classify_b1(0.0f, 0.0f, centers, 0.06f).contract ==
            policy::B1Contract::Centered,
        "Pimax centered b1 needs one correction");
    const auto corrected = policy::classify_b1(
        -0.210230276f, 0.0f, centers, 0.06f);
    require(corrected.contract == policy::B1Contract::AlreadyAsymmetric &&
            corrected.eye == 1,
        "Pimax corrected b1 rejects a second correction");
    require(policy::classify_b1(
        0.242512643f, 0.193187416f, centers, 0.06f).contract ==
            policy::B1Contract::Unknown,
        "Quest constants are not accepted as Pimax projection authority");
}

void test_small_and_ambiguous_centers_fail_closed() {
    const policy::RuntimeCenters small{{0.04f, -0.04f}, {0.0f, 0.0f}};
    require(policy::classify_b1(0.0f, 0.0f, small, 0.06f).contract ==
            policy::B1Contract::Centered,
        "small center exact zero remains centered");
    require(policy::classify_b1(0.04f, 0.0f, small, 0.06f).contract ==
            policy::B1Contract::AlreadyAsymmetric,
        "small center exact runtime value is already corrected");
    require(policy::classify_b1(0.02f, 0.0f, small, 0.06f).contract ==
            policy::B1Contract::Unknown,
        "equidistant small center does not guess");

    const policy::RuntimeCenters shared{{0.0f, 0.0f}, {0.1f, 0.1f}};
    const auto match = policy::match_eye(0.0f, 0.1f, shared, 0.06f);
    require(match.matched && match.eye == -1,
        "shared optical center cannot invent eye identity");
}

} // namespace

int main() {
    test_quest_centers();
    test_pimax_dream_air_centers();
    test_small_and_ambiguous_centers_fail_closed();
    std::cout << "focus/fire projection policy tests passed\n";
    return 0;
}
