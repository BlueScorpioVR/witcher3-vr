#include "command_list_identity.h"

#ifdef NDEBUG
#undef NDEBUG
#endif
#include <cassert>
#include <array>
#include <unordered_map>

using namespace w3vr::command_list_identity;

// IUnknown-only doubles model the documented QI/ownership boundary. They do
// not render or pretend to exercise D3D12 methods. The GPU probe covers those.
struct Node : IUnknown {
    Owner owner{Owner::Native};
    IUnknown* inner{};
    ULONG refs{1};
    uint32_t queries{};
    bool fail{};
    bool null_success{};
    bool graphics{true};

    HRESULT STDMETHODCALLTYPE QueryInterface(REFIID iid, void** out) override {
        ++queries;
        *out = nullptr;
        if (fail) return E_NOINTERFACE;
        if (null_success) return S_OK;
        if ((owner == Owner::Native || owner == Owner::RenderDoc) && graphics &&
            iid == __uuidof(ID3D12GraphicsCommandList)) {
            AddRef();
            *out = this;
            return S_OK;
        }
        if (((owner == Owner::Streamline && iid == kStreamlineBase) ||
             (owner == Owner::ReShade && iid == kReShadeBase)) && inner) {
            inner->AddRef();
            *out = inner;
            return S_OK;
        }
        return E_NOINTERFACE;
    }
    ULONG STDMETHODCALLTYPE AddRef() override { return ++refs; }
    ULONG STDMETHODCALLTYPE Release() override {
        assert(refs > 1); // No test node can lose its owner's reference.
        return --refs;
    }
};

Owner classify(const IUnknown* object) {
    return static_cast<const Node*>(object)->owner;
}

int main() {
    Node native{};
    Node renderdoc{}; renderdoc.owner = Owner::RenderDoc;
    Node streamline{}; streamline.owner = Owner::Streamline; streamline.inner = &native;
    Node reshade{}; reshade.owner = Owner::ReShade; reshade.inner = &native;
    auto* const expected = reinterpret_cast<ID3D12GraphicsCommandList*>(&native);
    auto* const renderdoc_expected =
        reinterpret_cast<ID3D12GraphicsCommandList*>(&renderdoc);
    assert(resolve(&native, classify).endpoint == expected);
    assert(resolve(&renderdoc, classify).endpoint == renderdoc_expected);
    assert(resolve(&streamline, classify).endpoint == expected);
    assert(resolve(&reshade, classify).endpoint == expected);
    assert(native.refs == 1 && renderdoc.refs == 1 &&
        streamline.refs == 1 && reshade.refs == 1);

    // The failing topology: the first wrapper contains another proxy, not a
    // direct D3D12 runtime pointer. Both orders must find the same native key.
    streamline.inner = &reshade;
    auto result = resolve(&streamline, classify);
    assert(result.endpoint == expected && result.wrappers == 2);
    streamline.inner = &native;
    reshade.inner = &streamline;
    result = resolve(&reshade, classify);
    assert(result.endpoint == expected && result.wrappers == 2);
    assert(native.refs == 1 && streamline.refs == 1 && reshade.refs == 1);

    // Missing/foreign interfaces are not guessed or returned as native.
    assert(resolve(nullptr, classify).failure == Failure::NullInput);
    assert(resolve(&native, nullptr).failure == Failure::NullInput);
    Node foreign{}; foreign.owner = Owner::Unknown;
    assert(resolve(&foreign, classify).failure == Failure::UnknownOwner);
    assert(foreign.queries == 0);
    streamline.inner = &foreign;
    assert(resolve(&reshade, classify).failure == Failure::UnknownOwner);
    assert(foreign.refs == 1 && streamline.refs == 1);
    streamline.inner = &native;
    streamline.fail = true;
    assert(resolve(&reshade, classify).failure == Failure::Query);
    streamline.fail = false;
    streamline.null_success = true;
    assert(resolve(&reshade, classify).failure == Failure::Query);
    streamline.null_success = false;
    native.graphics = false;
    assert(resolve(&reshade, classify).failure == Failure::Interface);
    native.graphics = true;
    assert(native.refs == 1 && streamline.refs == 1 && reshade.refs == 1);

    // Self-link and repeated-node cycles release even the rejected QI ref.
    streamline.inner = &streamline;
    assert(resolve(&streamline, classify).failure == Failure::Cycle);
    streamline.inner = &reshade;
    assert(resolve(&streamline, classify).failure == Failure::Cycle);
    assert(streamline.refs == 1 && reshade.refs == 1);

    std::array<Node, kMaxWrappers + 1> chain{};
    for (uint32_t n = 0; n < chain.size(); ++n) {
        chain[n].owner = (n & 1) ? Owner::ReShade : Owner::Streamline;
        chain[n].inner = n + 1 < chain.size() ? &chain[n + 1] : &native;
    }
    assert(resolve(&chain[0], classify).failure == Failure::Depth);
    result = resolve(&chain[1], classify);
    assert(result.endpoint == expected && result.wrappers == kMaxWrappers);
    for (const auto& node : chain) assert(node.refs == 1);

    // Regression for the six producer slots: keys from nested callbacks match
    // the native Execute keys for arbitrarily many frames without ring growth.
    std::unordered_map<ID3D12GraphicsCommandList*, uint64_t> pending;
    Node other_native{};
    streamline.inner = &reshade;
    for (uint64_t frame = 0; frame < 1024; ++frame) {
        Node* current_native = (frame & 1) ? &native : &other_native;
        reshade.inner = current_native;
        auto* const recorded_key = resolve(&streamline, classify).endpoint;
        assert(recorded_key != nullptr);
        pending[recorded_key] = frame;
        auto* const executed_key = resolve(current_native, classify).endpoint;
        const auto found = pending.find(executed_key);
        assert(found != pending.end() && found->second == frame);
        pending.erase(found);
        assert(pending.empty());
        assert(current_native->refs == 1 && reshade.refs == 1 && streamline.refs == 1);
    }

    // With the RenderDoc bridge active, Streamline's documented base link
    // terminates at RenderDoc's wrapper. ExecuteCommandLists is hooked on that
    // same wrapper, so producer and execution keys must remain pointer-exact.
    streamline.inner = &renderdoc;
    for (uint64_t frame = 0; frame < 1024; ++frame) {
        auto* const recorded_key = resolve(&streamline, classify).endpoint;
        auto* const executed_key = resolve(&renderdoc, classify).endpoint;
        assert(recorded_key == renderdoc_expected);
        assert(executed_key == renderdoc_expected);
        pending[recorded_key] = frame;
        const auto found = pending.find(executed_key);
        assert(found != pending.end() && found->second == frame);
        pending.erase(found);
        assert(pending.empty());
        assert(renderdoc.refs == 1 && streamline.refs == 1);
    }
    return 0;
}
