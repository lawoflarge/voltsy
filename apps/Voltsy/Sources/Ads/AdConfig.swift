// apps/Voltsy/Sources/Ads/AdConfig.swift
// AdMob configuration. Real production AdMob IDs (publisher pub-6563643868702361). The app ID
// is in Info.plist (GADApplicationIdentifier ~4806029723); the banner unit ID is below.
enum AdConfig {
    static let testBannerUnit = "ca-app-pub-3940256099942544/2934735716"   // Google test
    static let releaseBannerUnit = "ca-app-pub-6563643868702361/7240621379"
    /// Debug never touches the real publisher account: invalid traffic gets the whole
    /// AdMob account banned, not the single app. Mirrors InterstitialAdManager.unitID.
    static var bannerUnitID: String {
        #if DEBUG
        return testBannerUnit
        #else
        return releaseBannerUnit
        #endif
    }
    /// Skip ads for a new user's first sessions so they feel Volt's value first (spec §10).
    static let graceSessions = 3
}
