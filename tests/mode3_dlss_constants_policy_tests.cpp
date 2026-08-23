#include "mode3_dlss_constants_policy.h"

#include <cstdlib>

namespace {

void require(bool condition) {
    if (!condition) {
        std::abort();
    }
}

}  // namespace

int main() {
    using w3vr::mode3_dlss_constants::Receipt;
    using w3vr::mode3_dlss_constants::decide_builder_reentry;

    constexpr uint64_t pair = 42;
    constexpr uint32_t generation = 7;
    constexpr uint32_t frame = 900;
    const Receipt missing{};
    const Receipt peer{pair, generation, 1234, true};

    const auto strict = decide_builder_reentry(
        true, false, 0, pair, generation, frame, frame, missing, peer);
    require(strict.invoke);
    require(strict.peer_current);
    require(!strict.target_current);
    require(strict.forward_reset);

    const Receipt current{pair, generation, 1234, false};
    require(!decide_builder_reentry(
        true, false, 0, pair, generation, frame, frame, current, peer).invoke);
    require(!decide_builder_reentry(
        true, true, 0, pair, generation, frame, frame, missing, peer).invoke);
    require(!decide_builder_reentry(
        true, false, 1, pair, generation, frame, frame, missing, peer).invoke);
    require(!decide_builder_reentry(
        true, false, 0, pair, generation, frame, frame - 1, missing, peer).invoke);
    require(!decide_builder_reentry(
        true, false, 0, pair, generation, frame, frame, missing,
        Receipt{pair - 1, generation, 1234, true}).invoke);
    require(!decide_builder_reentry(
        true, false, 0, pair, generation, frame, frame, missing,
        Receipt{pair, generation - 1, 1234, true}).invoke);

    const auto no_reset = decide_builder_reentry(
        true, false, 0, pair, generation, frame, frame, missing,
        Receipt{pair, generation, 1234, false});
    require(no_reset.invoke);
    require(!no_reset.forward_reset);
    return 0;
}
