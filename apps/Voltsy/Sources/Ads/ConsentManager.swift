// apps/Voltsy/Sources/Ads/ConsentManager.swift
// GDPR/UMP consent + ATT pre-prompt + AdMob start, in Google's required order:
// UMP consent form first, then ATT, then MobileAds.start. `canShowAds` flips true once ads
// are permitted; a per-launch session counter feeds AdGate's ad-light grace period.
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

    /// Run once per launch after the user has seen Volt (called from Home.onAppear).
    func startIfNeeded() {
        guard !didStart else { return }
        didStart = true
        let params = RequestParameters()
        ConsentInformation.shared.requestConsentInfoUpdate(with: params) { [weak self] _ in
            Task { @MainActor in self?.presentFormThenATT() }
        }
    }

    private func presentFormThenATT() {
        ConsentForm.loadAndPresentIfRequired(from: Self.rootViewController()) { [weak self] _ in
            Task { @MainActor in self?.requestATTThenStart() }
        }
    }

    private func requestATTThenStart() {
        ATTrackingManager.requestTrackingAuthorization { [weak self] _ in
            Task { @MainActor in self?.startAds() }
        }
    }

    private func startAds() {
        guard ConsentInformation.shared.canRequestAds else { return }
        MobileAds.shared.start { _ in }
        canShowAds = true
    }

    @MainActor
    private static func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController
    }
}
