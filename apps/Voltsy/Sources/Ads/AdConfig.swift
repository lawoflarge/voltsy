// apps/Voltsy/Sources/Ads/AdConfig.swift
// AdMob configuration. These are Google's public TEST IDs — they serve test ads and never
// charge. Swap to the real AdMob unit IDs before the App Store release (see
// marketing/SUBMISSION-CHECKLIST.md). Test ads are valid on TestFlight.
enum AdConfig {
    static let bannerUnitID = "ca-app-pub-3940256099942544/2934735716"
    /// Skip ads for a new user's first sessions so they feel Volt's value first (spec §10).
    static let graceSessions = 3
}
