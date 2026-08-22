#include "route_flight_recorder.h"

#include <Windows.h>

#include <cstdlib>
#include <iostream>
#include <memory>

namespace {

void require(bool condition, const char* message) {
    if (!condition) {
        std::cerr << message << '\n';
        std::exit(1);
    }
}

}  // namespace

int main() {
    using namespace w3vr::route_flight;
    auto recorder = std::make_unique<Recorder>();

    Event event{};
    event.qpc = 100;
    event.present = 7;
    event.code = EventCode::DlssEvaluate;
    recorder->record(event);
    require(recorder->capture_since(0).events.empty(),
        "disabled recorder accepted an event");

    recorder->set_enabled(true);
    recorder->record(event);
    event.qpc = 200;
    event.present = 8;
    event.code = EventCode::TaauResolve;
    recorder->record(event);

    const auto complete = recorder->capture_since(0);
    require(complete.events.size() == 2,
        "enabled recorder did not retain both events");
    require(complete.events[0].sequence < complete.events[1].sequence,
        "route events are not ordered");
    require(complete.events[0].code == EventCode::DlssEvaluate &&
            complete.events[1].code == EventCode::TaauResolve,
        "route event payload changed");

    const auto filtered = recorder->capture_since(150);
    require(filtered.events.size() == 1 &&
            filtered.events[0].present == 8,
        "QPC window filtering failed");
    require(std::string(event_code_name(EventCode::AfwPublish)) ==
            "afw_publish",
        "event name table is incomplete");

    LARGE_INTEGER now{};
    require(QueryPerformanceCounter(&now) != FALSE,
        "QPC unavailable for dump test");
    set_enabled(true);
    Event global_event{};
    global_event.qpc = now.QuadPart;
    global_event.present = 9;
    global_event.code = EventCode::Present;
    record(global_event);
    std::wstring dump_path;
    require(dump_last_seconds("route-flight-test", 1, &dump_path),
        "route dump could not be written");
    require(GetFileAttributesW(dump_path.c_str()) != INVALID_FILE_ATTRIBUTES,
        "route dump path does not exist");
    require(DeleteFileW(dump_path.c_str()) != FALSE,
        "route dump test artifact could not be removed");
    set_enabled(false);
    return 0;
}
