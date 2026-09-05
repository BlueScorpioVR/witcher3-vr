#include "command_list_identity.h"
#include <dxgi1_4.h>
#include <wrl/client.h>
#include <array>
#include <cstdio>
#include <stdexcept>

using Microsoft::WRL::ComPtr;
using namespace w3vr::command_list_identity;

HMODULE reshade_module{};
const IUnknown* outer_identity{};

Owner classify(const IUnknown* object) {
    if (object == outer_identity) return Owner::Streamline;
    const auto vtable = *reinterpret_cast<void* const* const*>(object);
    HMODULE owner{};
    GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS |
        GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
        reinterpret_cast<LPCWSTR>(vtable[0]), &owner);
    if (owner == reshade_module) return Owner::ReShade;
    if (owner == GetModuleHandleW(L"D3D12Core.dll") ||
        owner == GetModuleHandleW(L"d3d12.dll")) return Owner::Native;
    return Owner::Unknown;
}

// Emulates only Streamline's published IUnknown/base-QI contract around a REAL
// ReShade graphics list. No Streamline runtime, game or NVIDIA addon is loaded.
struct OuterProxy : IUnknown {
    ComPtr<IUnknown> inner;
    ULONG refs{1};
    HRESULT STDMETHODCALLTYPE QueryInterface(REFIID iid, void** out) override {
        *out = nullptr;
        if (iid != kStreamlineBase) return E_NOINTERFACE;
        inner->AddRef();
        *out = inner.Get();
        return S_OK;
    }
    ULONG STDMETHODCALLTYPE AddRef() override { return ++refs; }
    ULONG STDMETHODCALLTYPE Release() override { return --refs; }
};

void check(HRESULT hr, const char* step) {
    if (FAILED(hr)) {
        std::printf("FAIL %s hr=%08lx\n", step, static_cast<unsigned long>(hr));
        throw std::runtime_error(step);
    }
}
void require(bool value, const char* step) {
    if (!value) throw std::runtime_error(step);
}

int wmain(int argc, wchar_t** argv) try {
    SetErrorMode(SEM_FAILCRITICALERRORS | SEM_NOGPFAULTERRORBOX);
    require(argc == 2, "Pass the absolute lab ReShade DLL path");
    LoadLibraryExW(L"dxgi.dll", nullptr, LOAD_LIBRARY_SEARCH_SYSTEM32);
    LoadLibraryExW(L"d3d12.dll", nullptr, LOAD_LIBRARY_SEARCH_SYSTEM32);
    reshade_module = LoadLibraryExW(argv[1], nullptr, LOAD_WITH_ALTERED_SEARCH_PATH);
    if (reshade_module == nullptr) {
        std::printf("ReShade LoadLibrary error=%lu\n", GetLastError());
    }
    require(reshade_module != nullptr, "load lab ReShade");
    using FactoryFunction = HRESULT(WINAPI*)(REFIID, void**);
    auto factory_function = reinterpret_cast<FactoryFunction>(
        GetProcAddress(reshade_module, "CreateDXGIFactory1"));
    auto device_function = reinterpret_cast<decltype(&D3D12CreateDevice)>(
        GetProcAddress(reshade_module, "D3D12CreateDevice"));
    require(factory_function && device_function, "ReShade exports");
    ComPtr<IDXGIFactory4> factory;
    check(factory_function(IID_PPV_ARGS(&factory)), "factory");
    ComPtr<IDXGIAdapter1> adapter;
    check(factory->EnumAdapters1(0, &adapter), "adapter");
    ComPtr<ID3D12Device> device;
    check(device_function(adapter.Get(), D3D_FEATURE_LEVEL_11_0,
        IID_PPV_ARGS(&device)), "device");
    ComPtr<ID3D12CommandAllocator> allocator;
    check(device->CreateCommandAllocator(D3D12_COMMAND_LIST_TYPE_DIRECT,
        IID_PPV_ARGS(&allocator)), "allocator");
    ComPtr<ID3D12GraphicsCommandList> proxy;
    check(device->CreateCommandList(0, D3D12_COMMAND_LIST_TYPE_DIRECT,
        allocator.Get(), nullptr, IID_PPV_ARGS(&proxy)), "command list");
    require(classify(proxy.Get()) == Owner::ReShade, "actual ReShade list required");
    ComPtr<IUnknown> unwrapped;
    check(proxy->QueryInterface(kReShadeBase,
        reinterpret_cast<void**>(unwrapped.GetAddressOf())), "ReShade base QI");
    ComPtr<ID3D12GraphicsCommandList> native;
    check(unwrapped.As(&native), "native graphics interface");
    require(classify(native.Get()) == Owner::Native, "actual native list required");

    OuterProxy outer;
    outer.inner = proxy;
    outer_identity = &outer;
    const std::array<IUnknown*, 3> inputs{native.Get(), proxy.Get(), &outer};
    for (uint32_t index = 0; index < inputs.size(); ++index) {
        const auto result = resolve(inputs[index], classify);
        require(result.native == native.Get() && result.wrappers == index &&
            result.failure == Failure::None, "native identity/depth mismatch");
        std::printf("PASS identity case=%u depth=%u native=%p\n",
            index, result.wrappers, result.native);
    }
    require(outer.refs == 1, "outer COM ownership changed");

    D3D12_RESOURCE_DESC buffer{};
    buffer.Dimension = D3D12_RESOURCE_DIMENSION_BUFFER;
    buffer.Width = 16; buffer.Height = 1; buffer.DepthOrArraySize = 1;
    buffer.MipLevels = 1; buffer.SampleDesc.Count = 1;
    buffer.Layout = D3D12_TEXTURE_LAYOUT_ROW_MAJOR;
    D3D12_HEAP_PROPERTIES heap{};
    heap.Type = D3D12_HEAP_TYPE_UPLOAD;
    ComPtr<ID3D12Resource> upload, readback;
    check(device->CreateCommittedResource(&heap, D3D12_HEAP_FLAG_NONE, &buffer,
        D3D12_RESOURCE_STATE_GENERIC_READ, nullptr, IID_PPV_ARGS(&upload)), "upload");
    heap.Type = D3D12_HEAP_TYPE_READBACK;
    check(device->CreateCommittedResource(&heap, D3D12_HEAP_FLAG_NONE, &buffer,
        D3D12_RESOURCE_STATE_COPY_DEST, nullptr, IID_PPV_ARGS(&readback)), "readback");
    const std::array<uint32_t, 4> pattern{0x15320001, 0x19370002, 0xdeadbeef, 0x12345678};
    void* memory{};
    D3D12_RANGE no_read{0, 0};
    check(upload->Map(0, &no_read, &memory), "upload map");
    memcpy(memory, pattern.data(), sizeof(pattern));
    upload->Unmap(0, nullptr);
    const auto resolved = resolve(&outer, classify);
    require(resolved.native != nullptr, "nested recording identity");
    resolved.native->CopyBufferRegion(readback.Get(), 0, upload.Get(), 0, sizeof(pattern));
    check(resolved.native->Close(), "close");
    D3D12_COMMAND_QUEUE_DESC queue_desc{};
    ComPtr<ID3D12CommandQueue> queue_proxy, queue;
    check(device->CreateCommandQueue(&queue_desc, IID_PPV_ARGS(&queue_proxy)), "queue");
    check(queue_proxy->QueryInterface(kReShadeBase,
        reinterpret_cast<void**>(queue.GetAddressOf())), "native queue");
    ID3D12CommandList* lists[]{resolved.native};
    queue->ExecuteCommandLists(1, lists);
    ComPtr<ID3D12Fence> fence;
    check(device->CreateFence(0, D3D12_FENCE_FLAG_NONE, IID_PPV_ARGS(&fence)), "fence");
    check(queue->Signal(fence.Get(), 1), "signal");
    HANDLE event = CreateEventW(nullptr, FALSE, FALSE, nullptr);
    require(event != nullptr, "fence event");
    check(fence->SetEventOnCompletion(1, event), "fence completion");
    const DWORD waited = WaitForSingleObject(event, 5000);
    CloseHandle(event);
    require(waited == WAIT_OBJECT_0, "GPU fence timeout");
    D3D12_RANGE read_range{0, sizeof(pattern)};
    check(readback->Map(0, &read_range, &memory), "readback map");
    const bool identical = memcmp(memory, pattern.data(), sizeof(pattern)) == 0;
    readback->Unmap(0, &no_read);
    require(identical, "GPU copied bytes differ");
    check(device->GetDeviceRemovedReason(), "device removal status");
    std::puts("PASS nested recording -> native Execute -> GPU fence -> exact readback");
    return 0;
} catch (const std::exception& error) {
    std::printf("FAIL %s\n", error.what());
    return 1;
}
