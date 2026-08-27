// apps/Voltsy/Sources/Ads/ConsentManager.swift
// ATT pre-prompt + GDPR/UMP consent + AdMob start. The ordering is load-bearing
// (Guideline 2.1 rejection 528ae9f3, same as RateRadar 50741e54): iOS silently drops
// the ATT prompt when it is requested before the scene is foreground-active or while
// another system alert is up, so VoltsyApp sequences the launch prompts at the first
// scenePhase == .active (+600ms): ATT → notifications → UMP/ads. ATT runs before any
// ad/consent network call so the prompt precedes data collection. `canShowAds` flips
// true once ads are permitted; a per-launch session counter feeds AdGate's grace period.
import SwiftUI
import AppTrackingTransparency
@preconcurrency import GoogleMobileAds
@preconcurrency import UserMessagingPlatform

@MainActor
@Observable
final class ConsentManager {
    private(set) var canShowAds = false
    private(set) var sessionCount: Int
    private var didStart = false

    init() {
        let key = "voltsy.sessionCount"
        let n = UserDefaults.standard.integer(forKey: key) + 1
        UserDefaults.standard.set(n, forKey: key)
        sessionCount = n
    }

    /// ATT prompt, suspended until the user responds — the caller sequences the
    /// notifications prompt behind it, because overlapping system permission alerts
    /// make iOS drop the ATT one. Only asks while undetermined; never blocks the app.
    func requestATTIfNeeded() async {
        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            _ = await ATTrackingManager.requestTrackingAuthorization()
        }
    }

    /// One-shot UMP consent (GDPR form where required) + Mobile Ads SDK start.
    /// Runs LAST in the launch sequence: with no consent message published the UMP
    /// form call can stall for a long time, so nothing user-facing may wait on it.
    func startAds() async {
        guard !didStart else { return }
        didStart = true
        do {
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: RequestParameters())
            try await ConsentForm.loadAndPresentIfRequired(from: Self.rootViewController())
        } catch {
            // Consent failure must never block the app.
        }
        guard ConsentInformation.shared.canRequestAds else { return }
        await MobileAds.shared.start()
        canShowAds = true
    }

    /// True inside the EEA/UK, where the UMP privacy options form exists. Gates the
    /// settings entry so users elsewhere never see a button that does nothing.
    var privacyOptionsRequired: Bool {
        ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }

    /// Re-opens the UMP privacy options form so a granted consent can be withdrawn
    /// as easily as it was given (GDPR Art. 7(3)).
    func presentPrivacyOptions() async {
        guard let root = Self.rootViewController() else { return }
        try? await ConsentForm.presentPrivacyOptionsForm(from: root)
    }

    @MainActor
    private static func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController
    }
}
