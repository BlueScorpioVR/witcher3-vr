#pragma once
#include <cstdint>
namespace w3vr::hud_publication {
constexpr bool ready(bool submitted, uint32_t eye, uint64_t pair) {
    return submitted && eye < 2 && pair != 0;
}
constexpr bool same_capture(uint32_t generation, uint64_t serial,
                            uint32_t receipt_generation, uint64_t receipt_serial) {
    return serial != 0 && generation == receipt_generation && serial == receipt_serial;
}
}
