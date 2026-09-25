#include "command_list_identity.h"

#include <array>

namespace w3vr::command_list_identity {
namespace {

HRESULT query(IUnknown* object, REFIID iid, void** result) noexcept {
    *result = nullptr;
    __try {
        return object->QueryInterface(iid, result);
    } __except (EXCEPTION_EXECUTE_HANDLER) {
        *result = nullptr;
        return E_FAIL;
    }
}

struct ChainReferences {
    std::array<IUnknown*, kMaxWrappers> values{};
    uint32_t count{};
    ~ChainReferences() {
        while (count != 0) {
            values[--count]->Release();
        }
    }
};

} // namespace

Resolution resolve(IUnknown* input, ClassifyOwner classify) noexcept {
    Resolution result{};
    if (input == nullptr || classify == nullptr) {
        result.failure = Failure::NullInput;
        return result;
    }
    ChainReferences references{};
    IUnknown* current = input;
    for (;;) {
        const Owner owner = classify(current);
        if (owner == Owner::Native || owner == Owner::RenderDoc) {
            ID3D12GraphicsCommandList* graphics{};
            const HRESULT hr = query(current, __uuidof(ID3D12GraphicsCommandList),
                reinterpret_cast<void**>(&graphics));
            if (SUCCEEDED(hr) && graphics != nullptr &&
                classify(graphics) == owner) {
                result.endpoint = graphics;
            } else {
                result.failure = Failure::Interface;
            }
            if (graphics != nullptr) {
                graphics->Release();
            }
            return result;
        }
        if (owner != Owner::Streamline && owner != Owner::ReShade) {
            result.failure = Failure::UnknownOwner;
            return result;
        }
        if (result.wrappers == kMaxWrappers) {
            result.failure = Failure::Depth;
            return result;
        }
        IUnknown* next{};
        const HRESULT hr = query(current,
            owner == Owner::Streamline ? kStreamlineBase : kReShadeBase,
            reinterpret_cast<void**>(&next));
        if (FAILED(hr) || next == nullptr) {
            if (next != nullptr) {
                next->Release();
            }
            result.failure = Failure::Query;
            return result;
        }
        bool cycle = next == input;
        for (uint32_t index = 0; index < references.count; ++index) {
            cycle = cycle || next == references.values[index];
        }
        if (cycle) {
            next->Release();
            result.failure = Failure::Cycle;
            return result;
        }
        references.values[references.count++] = next;
        ++result.wrappers;
        current = next;
    }
}

} // namespace w3vr::command_list_identity
