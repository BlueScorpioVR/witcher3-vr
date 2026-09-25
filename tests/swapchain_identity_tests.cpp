#include "swapchain_resource_identity.h"
#include <dxgi1_4.h>
#include <wrl/client.h>
#include <array>
#include <cstdio>
#include <stdexcept>

using Microsoft::WRL::ComPtr;
static void require(bool value, const char* message) {
    if (!value) throw std::runtime_error(message);
}
static void check(HRESULT result, const char* message) {
    if (FAILED(result)) {
        std::printf("HRESULT %08lx: %s\n", static_cast<unsigned long>(result), message);
        throw std::runtime_error(message);
    }
}
int main() try {
    static_assert(D3D12_RESOURCE_STATE_COMMON == D3D12_RESOURCE_STATE_PRESENT);
    ComPtr<IDXGIFactory4> factory;
    check(CreateDXGIFactory1(IID_PPV_ARGS(&factory)), "factory");
    ComPtr<IDXGIAdapter> warp;
    check(factory->EnumWarpAdapter(IID_PPV_ARGS(&warp)), "WARP adapter");
    ComPtr<ID3D12Device> device;
    check(D3D12CreateDevice(warp.Get(), D3D_FEATURE_LEVEL_11_0,
        IID_PPV_ARGS(&device)), "WARP device");
    D3D12_COMMAND_QUEUE_DESC queue_desc{};
    ComPtr<ID3D12CommandQueue> queue;
    check(device->CreateCommandQueue(&queue_desc, IID_PPV_ARGS(&queue)), "queue");
    HWND window = CreateWindowExW(0, L"STATIC", L"W3VR boundary test",
        WS_OVERLAPPEDWINDOW, 0, 0, 128, 128, nullptr, nullptr,
        GetModuleHandleW(nullptr), nullptr);
    require(window != nullptr, "hidden test window");
    DXGI_SWAP_CHAIN_DESC1 desc{};
    desc.Width = desc.Height = 64;
    desc.Format = DXGI_FORMAT_R8G8B8A8_UNORM;
    desc.SampleDesc.Count = 1;
    desc.BufferUsage = DXGI_USAGE_RENDER_TARGET_OUTPUT;
    desc.BufferCount = 3;
    desc.SwapEffect = DXGI_SWAP_EFFECT_FLIP_DISCARD;
    ComPtr<IDXGISwapChain1> swapchain;
    check(factory->CreateSwapChainForHwnd(queue.Get(), window, &desc, nullptr,
        nullptr, &swapchain), "swapchain");
    std::array<ComPtr<ID3D12Resource>, 3> buffers;
    for (UINT i = 0; i < buffers.size(); ++i) {
        check(swapchain->GetBuffer(i, IID_PPV_ARGS(&buffers[i])), "backbuffer");
        require(w3vr::swapchain_identity::owns_resource(swapchain.Get(), buffers[i].Get()),
            "all rotating backbuffers must be recognized");
    }
    auto texture_desc = buffers[0]->GetDesc();
    D3D12_HEAP_PROPERTIES heap{};
    heap.Type = D3D12_HEAP_TYPE_DEFAULT;
    std::array<ComPtr<ID3D12Resource>, 2> snapshots;
    for (UINT i = 0; i < snapshots.size(); ++i) {
        texture_desc.Format = i == 0 ? DXGI_FORMAT_R8G8B8A8_UNORM
                                    : DXGI_FORMAT_R16G16B16A16_FLOAT;
        check(device->CreateCommittedResource(&heap, D3D12_HEAP_FLAG_NONE,
            &texture_desc, D3D12_RESOURCE_STATE_COMMON, nullptr,
            IID_PPV_ARGS(&snapshots[i])), "private full-size snapshot");
        require(!w3vr::swapchain_identity::owns_resource(swapchain.Get(), snapshots[i].Get()),
            "private snapshot must not consume a game eye tag");
    }
    // Replay L/R final boundaries interleaved with the new FSR snapshots. The
    // previous size+COMMON rule consumes all four pending tags at private
    // transitions; the actual ownership query consumes them at game boundaries.
    std::array<ID3D12Resource*, 8> sequence{
        snapshots[1].Get(), buffers[0].Get(), snapshots[1].Get(), buffers[1].Get(),
        snapshots[0].Get(), buffers[2].Get(), snapshots[1].Get(), buffers[0].Get()};
    unsigned accepted = 0;
    for (unsigned i = 0; i < sequence.size(); ++i) {
        const auto resource_desc = sequence[i]->GetDesc();
        require(resource_desc.Width == desc.Width && resource_desc.Height == desc.Height,
            "reproducer must satisfy the old size-only criterion");
        const bool owns = w3vr::swapchain_identity::owns_resource(swapchain.Get(), sequence[i]);
        require(owns == ((i % 2) == 1), "only real L/R boundaries accepted");
        if (owns) ++accepted;
    }
    require(accepted == 4, "four original eye tags preserved");
    require(!w3vr::swapchain_identity::owns_resource(nullptr, buffers[0].Get()), "null swapchain");
    require(!w3vr::swapchain_identity::owns_resource(swapchain.Get(), nullptr), "null resource");
    swapchain.Reset();
    DestroyWindow(window);
    std::puts("PASS: identical-size RGBA8/RGBA16F private textures rejected; all actual backbuffers accepted; eye tags preserved");
    return 0;
} catch (const std::exception& error) {
    std::printf("FAIL: %s\n", error.what());
    return 1;
}
