#pragma once

#include <d3d12.h>
#include <cstdint>

namespace w3vr::command_list_identity {

enum class Owner { Unknown, Native, Streamline, ReShade };
enum class Failure { None, NullInput, UnknownOwner, Query, Cycle, Depth, Interface };

// Streamline's public legacy proxy contract, present in its v1.1.1 source:
// source/core/sl.api/internal.h / StreamlineRetreiveBaseInterface.
inline constexpr GUID kStreamlineBase = {
    0xadec44e2, 0x61f0, 0x45c3, {0xad, 0x9f, 0x1b, 0x37, 0x37, 0x92, 0x84, 0xff}};
// ReShade 6.8 source/com_utils.hpp / IID_UnwrappedObject.
inline constexpr GUID kReShadeBase = {
    0x7f2c9a11, 0x3b4e, 0x4d6a, {0x81, 0x2f, 0x5e, 0x9c, 0xd3, 0x7a, 0x1b, 0x42}};
inline constexpr uint32_t kMaxWrappers = 8;

using ClassifyOwner = Owner (*)(const IUnknown*);
struct Resolution {
    // Borrowed from the original input's ownership chain, not an added ref.
    // The caller must keep the input alive while using this identity.
    ID3D12GraphicsCommandList* native{};
    uint32_t wrappers{};
    Failure failure{Failure::None};
};

// Follows ONLY documented QI links of recognized wrappers. No field scanning,
// hard-coded layout offset or proxy-return fallback on an unresolved chain.
Resolution resolve(IUnknown* input, ClassifyOwner classify) noexcept;

} // namespace w3vr::command_list_identity
