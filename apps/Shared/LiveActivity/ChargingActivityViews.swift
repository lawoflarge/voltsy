// apps/Shared/LiveActivity/ChargingActivityViews.swift
// Presentation for the charging Live Activity, parameterized by ContentState (no ActivityKit
// context) so the same views render in the widget's ActivityConfiguration AND in the in-app
// dev gallery for simulator screenshot verification. Volt is the hero on Lock Screen +
// expanded Dynamic Island; the compact/minimal slots use a crisp bolt + percent.
#if canImport(ActivityKit)
import SwiftUI
import VoltsyCore
import VoltMascot

enum ChargingActivityCopy {
    static func eta(_ state: VoltActivityAttributes.ContentState) -> String {
        if state.isComplete { return "Full — you can unplug 💚" }
        let target = state.targetIsFull ? "full" : "80%"
        if let m = state.etaMinutes { return "≈\(m) min to \(target)" }
        return "Charging to \(target)…"
    }
}

struct ChargingLockScreenView: View {
    let state: VoltActivityAttributes.ContentState
    var body: some View {
        HStack(spacing: 14) {
            VoltView(state: state.voltState, size: 56)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.fill").foregroundStyle(.yellow)
                    Text("\(state.percent)%").font(.title3.bold().monospacedDigit())
                }
                Text(ChargingActivityCopy.eta(state))
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
    }
}

struct ChargingExpandedLeading: View {
    let state: VoltActivityAttributes.ContentState
    var body: some View { VoltView(state: state.voltState, size: 40) }
}

struct ChargingExpandedTrailing: View {
    let state: VoltActivityAttributes.ContentState
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "bolt.fill").foregroundStyle(.yellow)
            Text("\(state.percent)%").font(.title3.bold().monospacedDigit())
        }
    }
}

struct ChargingExpandedBottom: View {
    let state: VoltActivityAttributes.ContentState
    var body: some View {
        Text(ChargingActivityCopy.eta(state))
            .font(.subheadline).foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
    }
}
#endif
