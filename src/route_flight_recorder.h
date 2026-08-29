#pragma once

#include <array>
#include <atomic>
#include <cstddef>
#include <cstdint>
#include <string>
#include <vector>

namespace w3vr::route_flight {

// Route events are deliberately coarse. Producers never format strings, touch
// the filesystem, inspect GPU memory, or query a timer. One QPC value sampled
// by Present is shared by every event recorded during that Present interval.
enum class EventCode : uint16_t {
    Present = 0,
    PresentEnd,
    EngineTaskBegin,
    EngineTaskEnd,
    DlssEmit,
    DlssCommand,
    DlssConstants,
    DlssTag,
    DlssEvaluate,
    TaauResolve,
    TaauSubmission,
    AfwCapture,
    AfwFinalize,
    AfwEvaluate,
    AfwPublish,
    HudState,
    RouteReset,
    SmokeSelect,
    Count,
};

struct Event {
    uint64_t sequence{};
    int64_t qpc{};
    uint64_t present{};
    uint64_t pair_id{};
    uint64_t previous_pair_id{};
    uint32_t generation{};
    int32_t eye{-1};
    uint32_t thread_id{};
    EventCode code{EventCode::Present};
    uint16_t stage{};
    uint32_t flags{};
    uint32_t detail0{};
    uint32_t detail1{};
    uint32_t detail2{};
    uint32_t detail3{};
};

struct Snapshot {
    std::vector<Event> events;
    uint64_t total_claimed{};
    uint64_t overwritten{};
    uint64_t skipped_while_paused{};
};

class Recorder {
public:
    static constexpr size_t kCapacity = 65536;

    void set_enabled(bool enabled) noexcept;
    bool enabled() const noexcept;
    void record(Event event) noexcept;
    Snapshot capture_since(int64_t minimum_qpc);

private:
    std::array<Event, kCapacity> events_{};
    std::atomic<uint64_t> next_sequence_{};
    std::atomic<uint32_t> active_writers_{};
    std::atomic<uint64_t> skipped_while_paused_{};
    std::atomic<bool> paused_{};
    std::atomic<bool> enabled_{};
};

void set_enabled(bool enabled) noexcept;
bool enabled() noexcept;
void record(Event event) noexcept;

// F3-only path. Capturing pauses writers only while the bounded RAM ring is
// copied; formatting and file I/O happen after recording has resumed.
bool dump_last_seconds(
    const char* build_identity,
    uint32_t window_seconds = 15,
    std::wstring* written_path = nullptr);

const char* event_code_name(EventCode code) noexcept;

}  // namespace w3vr::route_flight
