#include "foliage_shader_orientation_policy.h"

#include <cassert>

int main() {
    using namespace w3vr::foliage_shader_orientation;

    static_assert(owner_for_shader_pair(
        kDistantTreesVsHash, kDistantTreesPsHash) == Owner::DistantTrees);
    static_assert(owner_for_shader_pair(
        kNearFrondsVsHash, kNearFrondsPsHash) == Owner::NearFronds);
    static_assert(owner_for_shader_pair(
        kDistantTreesVsHash, kNearFrondsPsHash) == Owner::None);
    static_assert(classify_owner(
        kNearFrondsVsHash, kNearFrondsPsHash,
        false, false, false, true, true) == Owner::NearFronds);
    static_assert(classify_owner(
        kNearFrondsVsHash, kNearFrondsPsHash,
        false, false, true, true, true) == Owner::None);
    static_assert(classify_owner(
        kDistantTreesVsHash, kDistantTreesPsHash,
        false, false, false, false, true) == Owner::None);
    static_assert(route_active(true, true));
    static_assert(!route_active(true, false));
    static_assert(!route_active(false, true));

    assert(owner_for_shader_pair(
        kDistantTreesVsHash, kDistantTreesPsHash) == Owner::DistantTrees);
    assert(owner_for_shader_pair(
        kNearFrondsVsHash, kNearFrondsPsHash) == Owner::NearFronds);
    return 0;
}
