#pragma once

#include <cstddef>
#include <cstdint>

namespace w3vr::cbv_descriptor_cache {

// CPU descriptor handles from different shader-visible heaps frequently share
// the same low address bits. Indexing only those bits clusters one descriptor
// offset from every heap into the same short probe window. Mix the complete
// immutable handle instead, while retaining the existing power-of-two table.
constexpr std::uint64_t mix_handle(std::uint64_t value) noexcept {
    value ^= value >> 30;
    value *= 0xbf58476d1ce4e5b9ULL;
    value ^= value >> 27;
    value *= 0x94d049bb133111ebULL;
    value ^= value >> 31;
    return value;
}

template <std::size_t SlotCount>
constexpr std::size_t slot_index(std::uintptr_t cpu_handle) noexcept {
    static_assert(SlotCount != 0);
    static_assert((SlotCount & (SlotCount - 1)) == 0);
    return static_cast<std::size_t>(mix_handle(cpu_handle)) & (SlotCount - 1);
}

} // namespace w3vr::cbv_descriptor_cache
