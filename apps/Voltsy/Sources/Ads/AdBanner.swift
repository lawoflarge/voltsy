// apps/Voltsy/Sources/Ads/AdBanner.swift
// Anchored adaptive AdMob banner wrapped for SwiftUI. Placed only on a secondary surface
// (the weekly recap), never the mascot home, and only when AdGate permits.
import SwiftUI
@preconcurrency import GoogleMobileAds

struct AdBanner: UIViewRepresentable {
    let adUnitID: String

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView()
        banner.adUnitID = adUnitID
        banner.adSize = currentOrientationAnchoredAdaptiveBanner(width: UIScreen.main.bounds.width)
        banner.rootViewController = Self.rootViewController()
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}

    @MainActor
    private static func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController
    }
}
