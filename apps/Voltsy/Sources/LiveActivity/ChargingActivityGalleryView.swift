// apps/Voltsy/Sources/LiveActivity/ChargingActivityGalleryView.swift
// Dev-only: renders the Lock Screen Live Activity view across ContentStates so we can verify
// the look via simulator screenshots (the simulator has no real charging event). Not shipped
// as a screen — temporarily set as the app root during verification, then reverted.
#if canImport(ActivityKit)
import SwiftUI
import VoltsyCore

struct ChargingActivityGalleryView: View {
    private let demos: [(String, VoltActivityAttributes.ContentState)] = [
        ("45% → 80%", .init(voltState: VoltState(mood: .charging, bellyFill: 0.45, tint: .green),
                            percent: 45, etaMinutes: 38, targetIsFull: false, isComplete: false)),
        ("82% → full", .init(voltState: VoltState(mood: .charging, bellyFill: 0.82, tint: .green),
                             percent: 82, etaMinutes: 22, targetIsFull: true, isComplete: false)),
        ("30%, no ETA yet", .init(voltState: VoltState(mood: .charging, bellyFill: 0.30, tint: .green),
                             percent: 30, etaMinutes: nil, targetIsFull: false, isComplete: false)),
        ("full", .init(voltState: VoltState(mood: .overcharged, bellyFill: 1.0, tint: .green),
                       percent: 100, etaMinutes: nil, targetIsFull: true, isComplete: true)),
    ]
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                Text("Charging Live Activity — Lock Screen").font(.headline).padding(.top, 12)
                ForEach(demos, id: \.0) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.0).font(.caption).foregroundStyle(.secondary)
                        ChargingLockScreenView(state: item.1)
                            .background(.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 18))
                            .environment(\.colorScheme, .dark)
                    }
                    .padding(.horizontal, 14)
                }
            }
        }
    }
}
#endif
