// Sources/Monetization/AdGate.swift
// Pure decision: should the free tier show ads right now? Pro is ad-free forever (the headline
// promise); ads also require obtained consent and are suppressed during the early ad-light grace
// period so a new user feels Volt's value first (spec §10). No UIKit/IO — unit-tested.
public enum AdGate {
    public static func shouldShowAds(isPro: Bool,
                                     hasConsent: Bool,
                                     completedSessions: Int,
                                     graceSessions: Int) -> Bool {
        if isPro { return false }
        if !hasConsent { return false }
        if completedSessions < graceSessions { return false }
        return true
    }
}
