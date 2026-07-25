// apps/Voltsy/Sources/History/ChargeHistoryView.swift
// P2 — honest "charge level over time" line chart. Free shows the last 7 days; Pro unlocks
// the full retained history. Never labeled capacity/health. Carries a dezent banner.
import SwiftUI
import Charts
import VoltsyCore
import BatteryEngines
import BatteryStore
import Monetization

struct ChargeHistoryView: View {
    let store: BatteryStore
    @Environment(ProStore.self) private var pro
    @Environment(ConsentManager.self) private var consent
    @State private var points: [ChargePoint] = []

    private var windowDays: Int { pro.isPro ? 90 : 7 }

    var body: some View {
        List {
            Section {
                if points.isEmpty {
                    Text("Getting to know your battery… check back after a little while.")
                        .foregroundStyle(.secondary)
                } else {
                    Chart(points) { p in
                        LineMark(x: .value("Time", p.timestamp),
                                 y: .value("Charge", p.level * 100))
                        .interpolationMethod(.monotone)
                        .foregroundStyle(.green)
                    }
                    .chartYScale(domain: 0...100)
                    .chartYAxisLabel("Charge level (%)")
                    .frame(height: 220)
                }
            } header: {
                Text(pro.isPro ? "Last 90 days" : "Last 7 days")
            } footer: {
                Text("Your charge level over time — not battery capacity or health.")
            }

            if !pro.isPro {
                Section {
                    Label("Unlock full history with Pro", systemImage: "sparkles")
                        .font(.subheadline.weight(.semibold))
                }
            }

            if Monetization.AdGate.shouldShowAds(isPro: pro.isPro, hasConsent: consent.canShowAds,
                                    completedSessions: consent.sessionCount,
                                    graceSessions: AdConfig.graceSessions) {
                Section { AdBanner(adUnitID: AdConfig.bannerUnitID).frame(height: 60) }
            }
        }
        .navigationTitle("Charge History")
        .navigationBarTitleDisplayMode(.inline)
        .task { reload() }
    }

    private func reload() {
        let since = Calendar.current.date(byAdding: .day, value: -windowDays, to: Date()) ?? Date()
        let samples = (try? store.samples(since: since)) ?? []
        points = ChargeHistoryEngine.points(from: samples, since: since)
    }
}
