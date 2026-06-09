// apps/Voltsy/Sources/Ads/AdConfig.swift
// AdMob configuration. Real production AdMob IDs (publisher pub-6563643868702361). The app ID
// is in Info.plist (GADApplicationIdentifier ~4806029723); the banner unit ID is below.
enum AdConfig {
    static let bannerUnitID = "ca-app-pub-6563643868702361/7240621379"
    /// Skip ads for a new user's first sessions so they feel Volt's value first (spec §10).
    static let graceSessions = 3
}
