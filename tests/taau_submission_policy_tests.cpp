#include "taau_submission_policy.h"

#ifdef NDEBUG
#undef NDEBUG
#endif
#include <cassert>

int main() {
    using w3vr::taau_submission::decide_authority;
    using w3vr::taau_submission::decide_cb10_producer_identity;
    using w3vr::taau_submission::decide_strict_raw_camera_fifo_action;
    using w3vr::taau_submission::recent_exact_submission_matches;
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

    // V1503 retains exact ExecuteCommandLists authority for the current pair
    // and for only the immediately preceding exact forward submission.
    assert(recent_exact_submission_matches(176, 174, 176));
    assert(recent_exact_submission_matches(176, 175, 175));
    assert(!recent_exact_submission_matches(176, 174, 175));
    assert(!recent_exact_submission_matches(176, 175, 174));
    assert(!recent_exact_submission_matches(176, 0, 175));
    assert(!recent_exact_submission_matches(0, 0, 175));
    assert(!recent_exact_submission_matches(176, 175, 0));
    assert(recent_exact_submission_matches(UINT64_MAX, UINT64_MAX - 1,
                                           UINT64_MAX));

    // The exact CB10 producer owns the current pair before engine_task_end.
    // There is intentionally no history-pair argument and therefore no path
    // which can replace pair 403 with already-committed pair 402.
    const auto cb10_current = decide_cb10_producer_identity(
        true, 0, 403, 9, 9, 0.0f);
    assert(cb10_current.valid);
    assert(cb10_current.eye == 0);
    assert(cb10_current.pair == 403);
    assert(cb10_current.generation == 9);

    assert(!decide_cb10_producer_identity(
        false, 0, 403, 9, 9, 0.0f).valid);
    assert(!decide_cb10_producer_identity(
        true, -1, 403, 9, 9, 0.0f).valid);
    assert(!decide_cb10_producer_identity(
        true, 2, 403, 9, 9, 0.0f).valid);
    assert(!decide_cb10_producer_identity(
        true, 0, 0, 9, 9, 0.0f).valid);
    assert(!decide_cb10_producer_identity(
        true, 0, UINT64_MAX, 9, 9, 0.0f).valid);
    assert(!decide_cb10_producer_identity(
        true, 0, 403, 8, 9, 0.0f).valid);
    assert(!decide_cb10_producer_identity(
        true, 0, 403, 9, 9, 0.000001f).valid);

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
