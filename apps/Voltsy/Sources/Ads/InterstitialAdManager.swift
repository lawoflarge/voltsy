// apps/Voltsy/Sources/Ads/InterstitialAdManager.swift
// Modern-API interstitial (GoogleMobileAds v13) with silent degradation: if no ad is
// loaded or presentation fails, the onDismiss continuation still fires so the app flow
// never stalls. Presented only at a natural break and only when the AdGate cap allows.
import SwiftUI
@preconcurrency import GoogleMobileAds

@MainActor enum RootVC {
    static func top() -> UIViewController? {
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }.first { $0.isKeyWindow }?.rootViewController
    }
}

@MainActor @Observable
final class InterstitialAdManager: NSObject, FullScreenContentDelegate {
    static let testUnit = "ca-app-pub-3940256099942544/4411468910"     // Google test
    static let releaseUnit = "ca-app-pub-6563643868702361/9475538486"
    private var ad: InterstitialAd?
    private var onDismiss: (() -> Void)?
    var isReady: Bool { ad != nil }
    private var unitID: String {
        #if DEBUG
        return Self.testUnit
        #else
        return Self.releaseUnit
        #endif
    }
    func preload() {
        guard ad == nil else { return }
        Task { let loaded = try? await InterstitialAd.load(with: unitID, request: Request())
            self.ad = loaded; loaded?.fullScreenContentDelegate = self }
    }
    func present(onDismiss: @escaping () -> Void) {
        guard let ad, let vc = RootVC.top() else { onDismiss(); return }
        self.onDismiss = onDismiss; ad.present(from: vc)
    }
    private func finish() { ad = nil; preload(); let cb = onDismiss; onDismiss = nil; cb?() }
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) { Task { @MainActor in self.finish() } }
    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) { Task { @MainActor in self.finish() } }
}
