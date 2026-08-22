#pragma once

#include <d3d12.h>

#include <array>
#include <cstdint>
#include <string>

namespace w3vr::smoke_visibility {

enum DrawFlags : uint32_t {
    DrawRouteAer = 1u << 0,
    DrawRouteStereo = 1u << 1,
    DrawBackendTaau = 1u << 2,
    DrawBackendDlss = 1u << 3,
    DrawBackendNoAa = 1u << 4,
    DrawAuthorityPresent = 1u << 5,
    DrawProducerTransaction = 1u << 6,
    DrawOffaxisRequested = 1u << 7,
    DrawVariantSelected = 1u << 8,
    DrawZeroCenterFallback = 1u << 9,
    DrawOriginalFallback = 1u << 10,
    DrawRootTablesReady = 1u << 11,
    DrawB1Captured = 1u << 12,
    DrawCinemaExcluded = 1u << 13,
    DrawFullVrExcluded = 1u << 14,
    DrawReferenceProbe = 1u << 15,
    DrawFreshEyeAuthority = 1u << 16,
};

struct DrawMetadata {
    uint64_t present{};
    uint64_t draw_group{};
    uint64_t pair_id{};
    uint32_t generation{UINT32_MAX};
    int32_t eye{-1};
    uint32_t pixel_projection{};
    uint32_t authority_route{};
    uint32_t producer_authority_route{};
    int32_t producer_eye{-1};
    uint64_t producer_pair_id{};
    uint32_t producer_generation{UINT32_MAX};
    uint32_t producer_pixel_projection{};
    uint32_t fresh_authority_route{};
    int32_t fresh_eye{-1};
    uint64_t fresh_pair_id{};
    float fresh_selected_distance{};
    float fresh_separation_margin{};
    int32_t variant_index{-1};
    uint32_t flags{};
    uint32_t index_count{};
    uint32_t instance_count{};
    uint32_t start_index{};
    int32_t base_vertex{};
    uint32_t start_instance{};
    uint32_t cull_mode{};
    uint32_t front_counter_clockwise{};
    uint32_t depth_clip_enable{};
    uint32_t viewport_count{};
    uint32_t scissor_count{};
    D3D12_VIEWPORT viewport{};
    D3D12_RECT scissor{};
    uintptr_t command_list{};
    uintptr_t original_pipeline{};
    uintptr_t selected_pipeline{};
    uint64_t root3_table{};
    uint64_t root6_table{};
    uint64_t b1_hash{};
    std::array<float, 16> clip_matrix{};
    std::array<float, 3> camera_position{};
};

struct DrawToken {
    uint32_t index{UINT32_MAX};
    bool query_started{};

    constexpr bool valid() const noexcept {
        return index != UINT32_MAX;
    }
};

// V1354 retains V1353's rendered draw plus three no-write projection probes
// and adds a diagnostic-only fresh camera/temporal-ledger eye decision beside
// the mutable command-list cache decision. Recording remains restricted to the
// exact smoke PSO and writes no files until the shared F3 edge.
bool initialize(ID3D12Device* device) noexcept;
void update_present_clock(uint64_t present) noexcept;
DrawToken begin_draw(
    ID3D12GraphicsCommandList* command_list,
    const DrawMetadata& metadata) noexcept;
void end_draw(
    ID3D12GraphicsCommandList* command_list,
    DrawToken token) noexcept;
void on_execute(
    ID3D12CommandQueue* queue,
    UINT num_command_lists,
    ID3D12CommandList* const* command_lists) noexcept;
void on_command_list_reset(ID3D12GraphicsCommandList* command_list) noexcept;
bool dump_last_seconds(
    const char* build_identity,
    uint32_t window_seconds = 15,
    std::wstring* written_path = nullptr);

}  // namespace w3vr::smoke_visibility
