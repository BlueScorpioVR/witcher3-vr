#pragma once
#include <d3d12.h>
#include <dxgi.h>

namespace w3vr::swapchain_identity {
// PRESENT aliases COMMON. Only resource ownership distinguishes an actual
// game backbuffer from an equally sized private DLSS/FSR capture texture.
inline bool owns_resource(IDXGISwapChain* swapchain,
                          ID3D12Resource* resource) noexcept {
    if (!swapchain || !resource) return false;
    DXGI_SWAP_CHAIN_DESC description{};
    if (FAILED(swapchain->GetDesc(&description))) return false;
    for (UINT index = 0; index < description.BufferCount; ++index) {
        ID3D12Resource* buffer{};
        if (FAILED(swapchain->GetBuffer(index, IID_PPV_ARGS(&buffer))) ||
            !buffer) continue;
        const bool match = buffer == resource;
        buffer->Release();
        if (match) return true;
    }
    return false;
}
}
