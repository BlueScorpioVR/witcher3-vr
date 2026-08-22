#include "mode3_transport_policy.h"

#ifdef NDEBUG
#undef NDEBUG
#endif
#include <cassert>
#include <initializer_list>

int main() {
    using w3vr::mode3_transport::AfwPixelProjection;
    using w3vr::mode3_transport::DlssCompletionOwner;
    using w3vr::mode3_transport::FinalTransport;
    using w3vr::mode3_transport::HudProjectionRoute;
    using w3vr::mode3_transport::TemporalAdapter;
    using w3vr::mode3_transport::afw_gameplay_capture_allowed;
    using w3vr::mode3_transport::afw_queued_producer_expired;
    using w3vr::mode3_transport::dlss_submission_route_active;
    using w3vr::mode3_transport::decide_final_submit;
    using w3vr::mode3_transport::decide_afw_pixel_projection;
    using w3vr::mode3_transport::decide_projection_pair;
    using w3vr::mode3_transport::decide_runtime_projection_transition;
    using w3vr::mode3_transport::dlss_completion_apply_public_jitter;
    using w3vr::mode3_transport::dlss_completion_capture_public_bundle;
    using w3vr::mode3_transport::dlss_completion_ngx_uses_public_bundle;
    using w3vr::mode3_transport::dlss_completion_resolved_owner;
    using w3vr::mode3_transport::exact_afw_backend;
    using w3vr::mode3_transport::final_backbuffer_route_active;
    using w3vr::mode3_transport::final_color_submission_backend;
    using w3vr::mode3_transport::immutable_pair_view_ready;
    using w3vr::mode3_transport::late_hud_composite_source_ready;
    using w3vr::mode3_transport::native_hud_source_bootstrap_active;
    using w3vr::mode3_transport::real_smoke_variant_bootstrap_allowed;
    using w3vr::mode3_transport::select_swapchain_dimension;
    using w3vr::mode3_transport::submission_queue_eligible;
    using w3vr::mode3_transport::streamline_dlss_evaluate_callback_active;
    using w3vr::mode3_transport::mode3_symmetric_subimage_active;
    using w3vr::mode3_transport::submitted_hud_join_route_active;
    using w3vr::mode3_transport::submitted_hud_join_window_matches;
    using w3vr::mode3_transport::native_asymmetric_effect_center_application_active;
    using w3vr::mode3_transport::decide_effect_draw_projection;
    using w3vr::mode3_transport::native_asymmetric_effect_preparation_configured;
    using w3vr::mode3_transport::strict_stereo_retained_hud_pair_fresh;
    using w3vr::mode3_transport::symmetric_producer_fov_scale;

    // Effect variants and their functional metadata are prepared before F2,
    // including a SYM startup, for both Stereo and AER. Draw substitution is
    // native-ASym-only and is suppressed for Cinema panels and Full VR scenes.
    const bool effect_preparation =
        native_asymmetric_effect_preparation_configured(
            true, true, true, true);
    assert(effect_preparation);
    assert(!native_asymmetric_effect_center_application_active(
        effect_preparation, false, false, false));
    assert(native_asymmetric_effect_center_application_active(
        effect_preparation, true, false, false));
    assert(!native_asymmetric_effect_center_application_active(
        effect_preparation, true, true, false));
    assert(!native_asymmetric_effect_center_application_active(
        effect_preparation, true, false, true));
    assert(!native_asymmetric_effect_preparation_configured(
        false, true, true, true));
    assert(!native_asymmetric_effect_preparation_configured(
        true, false, true, true));
    assert(!native_asymmetric_effect_preparation_configured(
        true, true, false, true));
    assert(!native_asymmetric_effect_preparation_configured(
        true, true, true, false));

    // Deferred smoke/fire correction follows the pixels that were actually
    // produced, not the live F2 request. Shared warm-up is a positive producer
    // result and must stop lookup; only native pixels select a per-eye centre.
    assert(decide_effect_draw_projection(
        AfwPixelProjection::NativeAsymmetric, true, 7, 7, true) ==
        AfwPixelProjection::NativeAsymmetric);
    assert(decide_effect_draw_projection(
        AfwPixelProjection::SharedSymmetric, true, 7, 7, false) ==
        AfwPixelProjection::SharedSymmetric);
    assert(decide_effect_draw_projection(
        AfwPixelProjection::NativeAsymmetric, false, 7, 7, true) ==
        AfwPixelProjection::Invalid);
    assert(decide_effect_draw_projection(
        AfwPixelProjection::NativeAsymmetric, true, 6, 7, true) ==
        AfwPixelProjection::Invalid);
    assert(decide_effect_draw_projection(
        AfwPixelProjection::NativeAsymmetric, true, 7, 7, false) ==
        AfwPixelProjection::Invalid);
    assert(decide_effect_draw_projection(
        AfwPixelProjection::Invalid, true, 7, 7, true) ==
        AfwPixelProjection::Invalid);

    // The public owner is intentionally narrow. Only Mode-3 OpenXR DLSS can
    // enter it. Projection is not an input, so AER and strict Stereo receive
    // the same callback policy.
    assert(streamline_dlss_evaluate_callback_active(
        true, true, 3, TemporalAdapter::Dlss));
    assert(!streamline_dlss_evaluate_callback_active(
        false, true, 3, TemporalAdapter::Dlss));
    assert(!streamline_dlss_evaluate_callback_active(
        true, false, 3, TemporalAdapter::Dlss));
    assert(!streamline_dlss_evaluate_callback_active(
        true, true, 2, TemporalAdapter::Dlss));
    assert(!streamline_dlss_evaluate_callback_active(
        true, true, 3, TemporalAdapter::Taau));

    // The first exact evaluation probes both boundaries. Once an owner is
    // observed, only that route records a normal per-frame producer. Public
    // jitter is delayed until the public route has actually been proven.
    assert(dlss_completion_capture_public_bundle(
        DlssCompletionOwner::Probe));
    assert(!dlss_completion_apply_public_jitter(
        DlssCompletionOwner::Probe));
    assert(!dlss_completion_capture_public_bundle(
        DlssCompletionOwner::Ngx));
    assert(dlss_completion_capture_public_bundle(
        DlssCompletionOwner::Streamline));
    assert(dlss_completion_apply_public_jitter(
        DlssCompletionOwner::Streamline));
    assert(dlss_completion_ngx_uses_public_bundle(
        DlssCompletionOwner::Probe, true));
    assert(!dlss_completion_ngx_uses_public_bundle(
        DlssCompletionOwner::Ngx, true));
    assert(dlss_completion_ngx_uses_public_bundle(
        DlssCompletionOwner::Streamline, true));
    assert(!dlss_completion_ngx_uses_public_bundle(
        DlssCompletionOwner::Streamline, false));
    assert(dlss_completion_resolved_owner(true) ==
        DlssCompletionOwner::Ngx);
    assert(dlss_completion_resolved_owner(false) ==
        DlssCompletionOwner::Streamline);

    // Projection is not an input: both symmetric and asymmetric exercise this
    // same policy and must obtain exactly the same answers.
    for (const bool native_asymmetric : {false, true}) {
        (void)native_asymmetric;
        assert(dlss_submission_route_active(true, TemporalAdapter::Dlss));
        assert(final_backbuffer_route_active(true, TemporalAdapter::Dlss));
        assert(final_backbuffer_route_active(true, TemporalAdapter::None));
        assert(!final_backbuffer_route_active(true, TemporalAdapter::Taau));

        assert(exact_afw_backend(true, false) == TemporalAdapter::Dlss);
        assert(exact_afw_backend(false, true) == TemporalAdapter::Taau);
        assert(final_color_submission_backend(true, false) ==
            TemporalAdapter::Dlss);
        assert(final_color_submission_backend(false, true) ==
            TemporalAdapter::Taau);
    }

    assert(!dlss_submission_route_active(false, TemporalAdapter::Dlss));
    assert(!dlss_submission_route_active(true, TemporalAdapter::Taau));
    assert(!final_backbuffer_route_active(false, TemporalAdapter::Dlss));
    assert(exact_afw_backend(false, false) == TemporalAdapter::None);
    assert(final_color_submission_backend(false, false) ==
        TemporalAdapter::None);

    const auto final_submit = decide_final_submit({
        true, true, 3072, 3264, 3072, 3264, true, true});
    assert(final_submit.transport == FinalTransport::DirectCopy);
    assert(final_submit.width == 3072 && final_submit.height == 3264);
    const auto identity_submit = decide_final_submit({
        true, true, 3072, 3264, 3072, 3264, true, true});
    assert(identity_submit.transport == FinalTransport::DirectCopy);
    assert(decide_final_submit({
        true, true, 2458, 2611, 3072, 3264, true, true})
        .transport == FinalTransport::Unavailable);

    // Mode 3 transports the complete selected-resolution texture into a
    // matching OpenXR destination. A genuine Mode-3 SYM source may select a
    // subImage from that texture, but the GPU handoff never resizes or pads it.
    assert(select_swapchain_dimension(
        true, 2496, 3072, 2496, 16384) == 2496);
    assert(select_swapchain_dimension(
        true, 2592, 3264, 2592, 16384) == 2592);
    assert(select_swapchain_dimension(
        true, 3072, 3072, 3072, 16384) == 3072);
    assert(select_swapchain_dimension(
        false, 2496, 3072, 3900, 16384) == 3900);
    assert(select_swapchain_dimension(
        true, 20000, 3072, 20000, 16384) == 16384);

    // Symmetric producer geometry covers both displaced runtime eyes and then
    // applies Presentation Size once. The calibrated Quest 3 cover is about
    // 0.804821; the final per-eye crop is tested in eye_geometry.
    const float symmetric_envelope =
        symmetric_producer_fov_scale(0.804821f, 1.0f);
    assert(symmetric_envelope > 1.24250f);
    assert(symmetric_envelope < 1.24253f);
    const float symmetric_at_point_eight =
        symmetric_producer_fov_scale(0.804821f, 0.8f);
    assert(symmetric_at_point_eight > 0.99400f);
    assert(symmetric_at_point_eight < 0.99402f);
    assert(symmetric_producer_fov_scale(1.0f, 1.0f) == 1.0f);
    assert(symmetric_producer_fov_scale(0.0f, 1.0f) == 2.0f);
    assert(symmetric_producer_fov_scale(2.0f, 1.0f) == 1.0f);

    // Every Mode-3 route maps a genuinely symmetric source to the per-eye
    // tangent interval. Runtime F2 changes the producer itself; it is not a
    // second optical gate. A native ASYM source always stays full-frame.
    assert(mode3_symmetric_subimage_active(true, false));
    assert(!mode3_symmetric_subimage_active(false, false));
    assert(!mode3_symmetric_subimage_active(true, true));

    // F2 requests are consumed only at an eligible safe boundary. Multiple
    // Present/Present1 observations collapse by parity, so two edges cannot
    // cause a needless generation reset.
    const auto sym_to_asym = decide_runtime_projection_transition(
        false, 1, true);
    assert(sym_to_asym.apply && sym_to_asym.native_asymmetric);
    const auto asym_to_sym = decide_runtime_projection_transition(
        true, 1, true);
    assert(asym_to_sym.apply && !asym_to_sym.native_asymmetric);
    const auto even_requests = decide_runtime_projection_transition(
        false, 2, true);
    assert(!even_requests.apply && !even_requests.native_asymmetric);
    const auto odd_requests = decide_runtime_projection_transition(
        true, 3, true);
    assert(odd_requests.apply && !odd_requests.native_asymmetric);
    const auto ineligible = decide_runtime_projection_transition(
        false, 1, false);
    assert(!ineligible.apply && !ineligible.native_asymmetric);

    // AER may publish through the final-eye cache, the packed cache or the
    // AFW sequencer. Whichever owner is selected, both eyes must prove the
    // same current generation and the same projection encoding.
    const auto symmetric_pair = decide_projection_pair(
        true, true, 7, 7, 7, false, false);
    assert(symmetric_pair.ready && !symmetric_pair.native_asymmetric);
    const auto asymmetric_pair = decide_projection_pair(
        true, true, 7, 7, 7, true, true);
    assert(asymmetric_pair.ready && asymmetric_pair.native_asymmetric);
    assert(!decide_projection_pair(
        false, true, 7, 7, 7, false, false).ready);
    assert(!decide_projection_pair(
        true, true, 6, 7, 7, false, false).ready);
    assert(!decide_projection_pair(
        true, true, 7, 7, 7, false, true).ready);

    // Centered AFW matrices do not classify the completed pixels. The exact
    // producer says Shared or Native; Native additionally proves the real eye
    // survived its factory rebuild. The synthesized peer needs no factory bit.
    assert(decide_afw_pixel_projection(
        AfwPixelProjection::NativeAsymmetric,
        true, 7, 7, true, 7, 0x1u, 0, true, false) ==
        AfwPixelProjection::NativeAsymmetric);
    assert(decide_afw_pixel_projection(
        AfwPixelProjection::NativeAsymmetric,
        true, 7, 7, true, 7, 0x2u, 0, true, false) ==
        AfwPixelProjection::Invalid);
    assert(decide_afw_pixel_projection(
        AfwPixelProjection::NativeAsymmetric,
        true, 7, 7, true, 7, 0x2u, 1, true, false) ==
        AfwPixelProjection::NativeAsymmetric);
    assert(decide_afw_pixel_projection(
        AfwPixelProjection::NativeAsymmetric,
        true, 7, 7, true, 7, 0x0u, 0, true, false) ==
        AfwPixelProjection::Invalid);
    assert(decide_afw_pixel_projection(
        AfwPixelProjection::NativeAsymmetric,
        true, 7, 7, true, 6, 0x1u, 0, true, false) ==
        AfwPixelProjection::Invalid);
    assert(decide_afw_pixel_projection(
        AfwPixelProjection::NativeAsymmetric,
        true, 7, 7, true, 7, 0x1u, 0, false, false) ==
        AfwPixelProjection::Invalid);
    assert(decide_afw_pixel_projection(
        AfwPixelProjection::SharedSymmetric,
        true, 7, 7, false, 0, 0, 0, false, true) ==
        AfwPixelProjection::SharedSymmetric);
    assert(decide_afw_pixel_projection(
        AfwPixelProjection::SharedSymmetric,
        true, 7, 7, false, 0, 0, 0, false, false) ==
        AfwPixelProjection::Invalid);
    assert(decide_afw_pixel_projection(
        AfwPixelProjection::Invalid,
        true, 7, 7, true, 7, 0x3u, 0, true, true) ==
        AfwPixelProjection::Invalid);

    // An exact command-list publication must be observable on either queue.
    assert(submission_queue_eligible(true, true));
    assert(submission_queue_eligible(true, false));
    assert(!submission_queue_eligible(false, true));
    assert(!submission_queue_eligible(false, false));

    // Native automatic Full VR can start before the debounced Cinema flag.
    // That early ownership edge must stop gameplay capture by itself so no
    // producer can be stranded while the final cutscene route is active.
    assert(afw_gameplay_capture_allowed(true, 0, false, false, false));
    assert(!afw_gameplay_capture_allowed(false, 0, false, false, false));
    assert(!afw_gameplay_capture_allowed(true, 1, false, false, false));
    assert(!afw_gameplay_capture_allowed(true, 0, true, false, false));
    assert(!afw_gameplay_capture_allowed(true, 0, false, true, false));
    assert(!afw_gameplay_capture_allowed(true, 0, false, false, true));

    // An unselectable AFW packet gets a short grace period, then loses to the
    // real-frame fallback so the fixed-size producer ring cannot deadlock.
    assert(!afw_queued_producer_expired(100, UINT64_MAX));
    assert(!afw_queued_producer_expired(100, 100));
    assert(!afw_queued_producer_expired(107, 100));
    assert(afw_queued_producer_expired(108, 100));
    assert(afw_queued_producer_expired(1000, 100));

    // Gameplay continuously removes the baked HUD. A cutscene or Cinema
    // boundary must fail open on its native HUD until the exact final pair
    // proves both eyes were rendered scene-only; otherwise the late layer
    // would draw the same subtitle a second time.
    assert(late_hud_composite_source_ready(
        HudProjectionRoute::Gameplay, false));
    assert(late_hud_composite_source_ready(
        HudProjectionRoute::Gameplay, true));
    assert(!late_hud_composite_source_ready(
        HudProjectionRoute::FullVr, false));
    assert(late_hud_composite_source_ready(
        HudProjectionRoute::FullVr, true));
    assert(!late_hud_composite_source_ready(
        HudProjectionRoute::Cinema, false));
    assert(late_hud_composite_source_ready(
        HudProjectionRoute::Cinema, true));

    // Every retained-HUD route must be able to discover native t1 before the
    // first complete scene-only pair exists. Strict Stereo previously omitted
    // its bootstrap and could not transition away from the baked HUD.
    assert(native_hud_source_bootstrap_active(true, false, false));
    assert(native_hud_source_bootstrap_active(false, true, false));
    assert(native_hud_source_bootstrap_active(false, false, true));
    assert(!native_hud_source_bootstrap_active(false, false, false));

    // Cross-command-list retained HUD metadata is admitted only inside the
    // short recording/submission interval for the current renderer generation.
    // A one- or two-Present skew is possible when worker lists straddle the
    // counter edge; anything older remains on the baked fail-open path.
    assert(submitted_hud_join_window_matches(7, 7, 100, 100));
    assert(submitted_hud_join_window_matches(7, 7, 99, 100));
    assert(submitted_hud_join_window_matches(7, 7, 98, 100));
    assert(submitted_hud_join_window_matches(7, 7, 102, 100));
    assert(!submitted_hud_join_window_matches(7, 7, 97, 100));
    assert(!submitted_hud_join_window_matches(7, 8, 100, 100));

    // A stale retained HUD must not outlive loading and darken newer Stereo
    // scene pairs. Bootstrap remains on the native baked HUD until a retained
    // pair reaches the exact predecessor target in the current generation.
    assert(!strict_stereo_retained_hud_pair_fresh(7, 7, 0, 7, 1));
    assert(!strict_stereo_retained_hud_pair_fresh(7, 7, 100, 7, 99));
    assert(!strict_stereo_retained_hud_pair_fresh(7, 6, 100, 7, 100));
    assert(!strict_stereo_retained_hud_pair_fresh(7, 7, 100, 6, 100));
    assert(strict_stereo_retained_hud_pair_fresh(7, 7, 100, 7, 100));
    assert(strict_stereo_retained_hud_pair_fresh(7, 7, 100, 7, 101));

    // AER retains its AFW-scoped contract. Strict Stereo uses the same
    // submitted-order safety net for both temporal backends, but not No AA.
    assert(submitted_hud_join_route_active(
        true, true, true, TemporalAdapter::Dlss));
    assert(submitted_hud_join_route_active(
        true, true, true, TemporalAdapter::Taau));
    assert(!submitted_hud_join_route_active(
        true, true, false, TemporalAdapter::Dlss));
    assert(submitted_hud_join_route_active(
        true, false, false, TemporalAdapter::Dlss));
    assert(submitted_hud_join_route_active(
        true, false, false, TemporalAdapter::Taau));
    assert(!submitted_hud_join_route_active(
        true, false, false, TemporalAdapter::None));
    assert(!submitted_hud_join_route_active(
        false, false, false, TemporalAdapter::Dlss));

    // Runtime FOV is required only for the two optical-centre variants. The
    // independent world-up fallback must never depend on first-camera timing.
    assert(!real_smoke_variant_bootstrap_allowed(0, false));
    assert(!real_smoke_variant_bootstrap_allowed(1, false));
    assert(real_smoke_variant_bootstrap_allowed(2, false));
    assert(real_smoke_variant_bootstrap_allowed(0, true));
    assert(real_smoke_variant_bootstrap_allowed(1, true));
    assert(real_smoke_variant_bootstrap_allowed(2, true));
    assert(!real_smoke_variant_bootstrap_allowed(3, true));

    // AER Cinema keeps its completed pixels in the packed resources without
    // publishing the unrelated strict-Stereo packed-valid bit. Its completed
    // pair authority must still select the matching immutable XrView. During
    // the next half-pair, advancing staging views must never replace it.
    assert(immutable_pair_view_ready(true, false, true));
    assert(!immutable_pair_view_ready(true, false, false));
    assert(immutable_pair_view_ready(false, true, true));
    assert(!immutable_pair_view_ready(false, false, true));
    return 0;
}
