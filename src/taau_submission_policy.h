#pragma once

#include <cstdint>

namespace w3vr::taau_submission {

struct AuthorityDecision {
    uint64_t effective_pair{};
    bool preserve_previous{};
};

struct ProducerIdentityDecision {
    int32_t eye{-1};
    uint64_t pair{};
    uint32_t generation{};
    bool valid{};
};

// The TAAU CB10 camera is produced from one immutable temporal-matrix record.
// That record is the sole owner of the current Stereo resolve identity. The
// committed eye history is deliberately absent from this decision: it may name
// only the previous temporal frame and must never be substituted for current.
constexpr ProducerIdentityDecision decide_cb10_producer_identity(
    bool matrix_record_valid,
    int32_t matrix_eye,
    uint64_t matrix_pair,
    uint32_t matrix_generation,
    uint32_t current_generation,
    float matrix_error) noexcept {
    const bool valid = matrix_record_valid && matrix_eye >= 0 && matrix_eye <= 1 &&
        matrix_pair != 0 && matrix_pair != ~uint64_t{0} &&
        current_generation != 0 && matrix_generation == current_generation &&
        matrix_error == 0.0f;
    return valid
        ? ProducerIdentityDecision{
              matrix_eye, matrix_pair, matrix_generation, true}
        : ProducerIdentityDecision{};
}

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

// A captured pair remains publishable when it is either the newest exact
// resolve submitted for this eye, or the immediately preceding exact forward
// submission and the newest submission is exactly one pair newer. This keeps
// the V12049 ExecuteCommandLists proof while tolerating the one-eye, one-pair
// phase shift observed after a Stereo TAAU Cinema recenter.
constexpr bool recent_exact_submission_matches(
    uint64_t latest_pair,
    uint64_t previous_forward_pair,
    uint64_t candidate_pair) noexcept {
    if (candidate_pair == 0 || latest_pair == 0) {
        return false;
    }
    if (latest_pair == candidate_pair) {
        return true;
    }
    return candidate_pair != UINT64_MAX &&
        latest_pair == candidate_pair + 1 &&
        previous_forward_pair == candidate_pair;
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
