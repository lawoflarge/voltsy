// apps/Voltsy/Sources/Tips/CareTipsView.swift
// F3 — calm, evidence-based care tips. Secondary surface that also carries a dezent banner.
import SwiftUI
import BatteryEngines
import Monetization

struct CareTipsView: View {
    @Environment(ProStore.self) private var pro
    @Environment(ConsentManager.self) private var consent

    var body: some View {
        List {
            Section {
                ForEach(CareTips.all) { tip in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: tip.icon).font(.title3).frame(width: 28)
                            .foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(tip.title).font(.headline)
                            Text(tip.body).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } footer: {
                Text("General battery-care habits — not a diagnosis of your specific battery.")
            }

            if AdGate.shouldShowAds(isPro: pro.isPro, hasConsent: consent.canShowAds,
                                    completedSessions: consent.sessionCount,
                                    graceSessions: AdConfig.graceSessions) {
                Section { AdBanner(adUnitID: AdConfig.bannerUnitID).frame(height: 60) }
            }
        }
        .navigationTitle("Volt's Care Tips")
        .navigationBarTitleDisplayMode(.inline)
    }
}
