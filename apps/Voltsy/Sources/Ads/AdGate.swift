// apps/Voltsy/Sources/Ads/AdGate.swift
// Interstitial frequency-cap gate (canonical ad pattern). Protects ratings/conversion:
// no interstitial before the 2nd session and never within 180s of the previous one.
// This is the interstitial cap; the banner's show/hide decision lives in the separate
// Monetization.AdGate.shouldShowAds(...) (grace period + consent) used on secondary surfaces.
import Foundation

@MainActor @Observable final class AdGate {
    private let minInterval: TimeInterval = 180
    private let lastKey = "ad_last_interstitial"
    private let sessKey = "ad_session_count"
    /// true only from the 2nd session AND when >=180s since the last interstitial.
    var canShowInterstitial: Bool {
        guard UserDefaults.standard.integer(forKey: sessKey) >= 2 else { return false }
        let last = UserDefaults.standard.double(forKey: lastKey)
        return Date().timeIntervalSince1970 - last >= minInterval
    }
    func recordInterstitial() { UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastKey) }
    static func bumpSession() {
        let d = UserDefaults.standard
        d.set(d.integer(forKey: "ad_session_count") + 1, forKey: "ad_session_count")
    }
}
