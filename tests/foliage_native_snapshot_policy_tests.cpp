#include "foliage_native_snapshot_policy.h"

#include <cassert>

int main() {
    using namespace w3vr::foliage_native_snapshot;

    static_assert(shader_pair_is_owner(
        kDistantTreesVsHash, kDistantTreesPsHash));
    static_assert(shader_pair_is_owner(kNearFrondsVsHash, kNearFrondsPsHash));
    static_assert(!shader_pair_is_owner(
        kDistantTreesVsHash, kNearFrondsPsHash));
    static_assert(is_owner(
        kNearFrondsVsHash, kNearFrondsPsHash,
        false, false, false, true, true));
    static_assert(!is_owner(
        kNearFrondsVsHash, kNearFrondsPsHash,
        false, false, true, true, true));
    static_assert(route_active(true, true));
    static_assert(!route_active(true, false));
    return 0;
}
