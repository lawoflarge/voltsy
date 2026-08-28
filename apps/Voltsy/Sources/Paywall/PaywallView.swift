// apps/Voltsy/Sources/Paywall/PaywallView.swift
// Value-first, one-time paywall (spec §10): the user has already felt Volt; lead with the
// emotional ad-free promise, not dry diagnostics. Restore is prominent and bulletproof.
import SwiftUI
import VoltsyCore
import VoltMascot
import Monetization

struct PaywallView: View {
    let store: ProStore
    @Environment(\.dismiss) private var dismiss

    // Every line here must map to code that actually gates on `isPro`. Cosmetics/skins and
    // "deluxe widgets" were advertised without any implementation behind them and are gone;
    // the custom alert thresholds are a real Pro gate that was never named.
    private let perks: [(String, String)] = [
        ("bolt.slash.fill", "Zero ads, forever"),
        ("clock.arrow.circlepath", "Full battery history & insights"),
        ("snowflake", "Unlimited Power Nap streak freezes"),
        ("bell.badge", "Custom charge alert thresholds"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                VoltView(state: VoltState(mood: .energetic, bellyFill: 1.0, tint: .green), size: 130)
                    .frame(height: 140).padding(.top, 12)

                VStack(spacing: 6) {
                    Text("Keep Volt happy forever").font(.title.bold())
                        .multilineTextAlignment(.center)
                    Text("Pay once. Never see an ad again.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 14) {
                    ForEach(perks, id: \.1) { perk in
                        HStack(spacing: 12) {
                            Image(systemName: perk.0).font(.headline)
                                .foregroundStyle(.green).frame(width: 26)
                            Text(perk.1).font(.subheadline)
                            Spacer()
                        }
                    }
                }
                .padding().frame(maxWidth: .infinity)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 18))

                Button {
                    Task { await store.purchase(); if store.isPro { dismiss() } }
                } label: {
                    HStack {
                        if store.purchaseInFlight { ProgressView().tint(.white) }
                        Text(store.purchaseInFlight ? "Processing…"
                             : store.displayPrice.isEmpty ? "Unlock Voltsy Pro"
                             : "Unlock Pro — \(store.displayPrice) once")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .disabled(store.purchaseInFlight || store.product == nil)

                Button("Restore Purchases") {
                    Task { await store.restore(); if store.isPro { dismiss() } }
                }
                .font(.subheadline.weight(.semibold))

                Text("One-time purchase, no subscription. Pro is tied to your Apple ID and restores on every device.")
                    .font(.caption2).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: { Image(systemName: "xmark.circle.fill") }
                .font(.title2).foregroundStyle(.secondary).padding()
        }
        .task { if store.product == nil { await store.refresh() } }
    }
}
