// apps/Voltsy/Sources/VoltsyApp.swift
import SwiftUI
import BatteryStore
import Monetization

@main
struct VoltsyApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var consentScheduled = false
    @State private var model: HomeViewModel = {
        // App Group is deferred until the Widget/Live Activity ships. Calling shared()
        // without the entitlement is a hard SwiftData fatalError (NOT a catchable throw),
        // so `try?` can't save us — use the on-device store directly for now.
        let store = (try? BatteryStore.local()) ?? BatteryStore.inMemoryFallback()
        return HomeViewModel(store: store)
    }()
    @State private var proStore = ProStore()
    @State private var consent = ConsentManager()
    @State private var gate = AdGate()
    @State private var interstitial = InterstitialAdManager()

    var body: some Scene {
        WindowGroup {
            if let captureScreen = ScreenshotMode.requested {
                // App Store screenshot capture mode (scripts/glowup/capture.mjs):
                // render a deterministic marketing screen, no permission prompts, no ads.
                ScreenshotHost(screen: captureScreen)
            } else {
                HomeView(model: model)
                    .environment(proStore)
                    .environment(consent)
                    .environment(gate)
                    .environment(interstitial)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Launch permission prompts are strictly sequenced from the first
            // foreground-active moment (+600ms): ATT → UMP consent → notifications.
            // Requesting ATT during launch or while another system alert is up makes
            // iOS drop the prompt silently (Guideline 2.1 rejection 528ae9f3).
            guard ScreenshotMode.requested == nil, newPhase == .active, !consentScheduled else { return }
            consentScheduled = true
            // Interstitial session counter (canonical AdGate cap): bump once per launch so
            // canShowInterstitial only unlocks from the 2nd session onward.
            AdGate.bumpSession()
            Task {
                try? await Task.sleep(for: .milliseconds(600))
                if !proStore.isPro { await consent.requestATTIfNeeded() }
                await model.requestNotificationPermission()
                if !proStore.isPro {
                    await consent.startAds()
                    interstitial.preload()
                }
            }
        }
    }
}
