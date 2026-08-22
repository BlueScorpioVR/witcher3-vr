#include "cbv_descriptor_cache_policy.h"

#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <unordered_set>

namespace {

void require(bool condition, const char* message) {
    if (!condition) {
        std::cerr << message << '\n';
        std::exit(1);
    }
}

} // namespace

int main() {
    constexpr std::size_t kSlotCount = 1u << 20;
    constexpr std::uintptr_t kDescriptorStride = 32;
    constexpr std::uintptr_t kAliasingHeapSpan =
        kSlotCount * kDescriptorStride;
    constexpr std::uintptr_t kDescriptorOffset = 173 * kDescriptorStride;

    std::unordered_set<std::size_t> distributed_indices;
    for (std::uintptr_t heap = 0; heap < 128; ++heap) {
        const auto handle = kDescriptorOffset + heap * kAliasingHeapSpan;
        const auto legacy_index = (handle >> 5) & (kSlotCount - 1);
        require(legacy_index == 173,
            "fixture must reproduce the former cross-heap alias");
        distributed_indices.insert(
            w3vr::cbv_descriptor_cache::slot_index<kSlotCount>(handle));
    }
    require(distributed_indices.size() == 128,
        "complete handles must not collapse separate heaps into one probe run");

    constexpr auto handle = static_cast<std::uintptr_t>(0x12345678000ULL);
    constexpr auto first =
        w3vr::cbv_descriptor_cache::slot_index<kSlotCount>(handle);
    constexpr auto repeated =
        w3vr::cbv_descriptor_cache::slot_index<kSlotCount>(handle);
    static_assert(first == repeated);
    require(first == repeated, "the same descriptor handle must be stable");
    require(first < kSlotCount, "the mixed index must remain in table bounds");
    return 0;
}
