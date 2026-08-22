#pragma once

#include <cstdint>

namespace w3vr::taau_submission {

struct AuthorityDecision {
    uint64_t effective_pair{};
    bool preserve_previous{};
};

// A stale resolve does not contain the pixels named by its old producer tag:
// it copies the already-valid private eye history instead. It therefore must
// not change submitted-pair authority in either direction. Normal resolves
// retain the established last-submission semantics, including diagnostics for
// unexpected non-forward ordering.
constexpr AuthorityDecision decide_authority(
    uint64_t previous_pair,
    uint64_t incoming_pair,
    bool replayed_as_stale) {
    return replayed_as_stale
        ? AuthorityDecision{previous_pair, true}
        : AuthorityDecision{incoming_pair, false};
}

// AFW TAAU camera payloads and native resolves are two views of the same
// ordered alternating producer stream. The front payload is usable only when
// generation, routed eye and the resolve-matrix validation all agree. A later
// payload must never be searched for as a substitute.
constexpr bool strict_raw_camera_fifo_entry_matches(
    uint32_t expected_generation,
    uint32_t expected_eye,
    uint32_t producer_generation,
    uint32_t producer_eye,
    bool matrix_valid) noexcept {
    return expected_eye <= 1 && producer_eye == expected_eye &&
        producer_generation == expected_generation && matrix_valid;
}

enum class StrictRawCameraFifoAction : uint8_t {
    Reject,
    Wait,
    Consume,
};

// The consumer must not remove an otherwise-valid front producer merely
// because the resolve currently names the opposite eye. In an alternating
// stream that producer belongs to the next resolve; retaining it for one turn
// is the FIFO barrier which deterministically repairs a one-eye phase offset.
constexpr StrictRawCameraFifoAction decide_strict_raw_camera_fifo_action(
    uint32_t expected_generation,
    uint32_t expected_eye,
    bool producer_available,
    bool producer_valid,
    uint32_t producer_generation,
    uint32_t producer_eye,
    bool matrix_valid) noexcept {
    if (!producer_available || !producer_valid || expected_eye > 1 ||
        producer_eye > 1 || producer_generation != expected_generation) {
        return StrictRawCameraFifoAction::Reject;
    }
    if (producer_eye != expected_eye) {
        return StrictRawCameraFifoAction::Wait;
    }
    return matrix_valid
        ? StrictRawCameraFifoAction::Consume
        : StrictRawCameraFifoAction::Reject;
}

}  // namespace w3vr::taau_submission
