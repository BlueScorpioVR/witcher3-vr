#include "taau_submission_policy.h"

#include <cassert>

int main() {
    using w3vr::taau_submission::decide_authority;
    using w3vr::taau_submission::decide_strict_raw_camera_fifo_action;
    using w3vr::taau_submission::StrictRawCameraFifoAction;
    using w3vr::taau_submission::strict_raw_camera_fifo_entry_matches;

    const auto forward = decide_authority(1603, 1604, false);
    assert(!forward.preserve_previous);
    assert(forward.effective_pair == 1604);

    // Existing behavior for a non-stale submission is intentionally unchanged.
    const auto unexpected_backward = decide_authority(1613, 1604, false);
    assert(!unexpected_backward.preserve_previous);
    assert(unexpected_backward.effective_pair == 1604);

    // The V1258 ASYM trace contains this exact stale ordering. Its replay copies
    // the private history and must leave V12049 authority at pair 1613.
    const auto stale_backward = decide_authority(1613, 1604, true);
    assert(stale_backward.preserve_previous);
    assert(stale_backward.effective_pair == 1613);

    const auto stale_equal = decide_authority(1613, 1613, true);
    assert(stale_equal.preserve_previous);
    assert(stale_equal.effective_pair == 1613);

    // With no submitted authority, a replay cannot invent one. The existing
    // exact-pair gate remains fail-closed until a normal resolve submits.
    const auto stale_without_authority = decide_authority(0, 1604, true);
    assert(stale_without_authority.preserve_previous);
    assert(stale_without_authority.effective_pair == 0);

    assert(strict_raw_camera_fifo_entry_matches(7, 0, 7, 0, true));
    assert(strict_raw_camera_fifo_entry_matches(7, 1, 7, 1, true));
    assert(!strict_raw_camera_fifo_entry_matches(7, 0, 7, 1, true));
    assert(!strict_raw_camera_fifo_entry_matches(7, 0, 6, 0, true));
    assert(!strict_raw_camera_fifo_entry_matches(7, 0, 7, 0, false));

    assert(decide_strict_raw_camera_fifo_action(
        7, 0, true, true, 7, 0, true) ==
        StrictRawCameraFifoAction::Consume);
    assert(decide_strict_raw_camera_fifo_action(
        7, 1, true, true, 7, 0, false) ==
        StrictRawCameraFifoAction::Wait);
    assert(decide_strict_raw_camera_fifo_action(
        7, 0, true, true, 7, 1, false) ==
        StrictRawCameraFifoAction::Wait);
    assert(decide_strict_raw_camera_fifo_action(
        7, 0, true, true, 7, 0, false) ==
        StrictRawCameraFifoAction::Reject);
    assert(decide_strict_raw_camera_fifo_action(
        7, 0, true, true, 6, 1, true) ==
        StrictRawCameraFifoAction::Reject);
    assert(decide_strict_raw_camera_fifo_action(
        7, 0, false, false, 0, UINT32_MAX, false) ==
        StrictRawCameraFifoAction::Reject);

    return 0;
}
