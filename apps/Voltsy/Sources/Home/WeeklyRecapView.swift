// apps/Voltsy/Sources/Home/WeeklyRecapView.swift
// "This week with Volt" recap card (spec §200) — screenshot-optimized for organic shares.
import SwiftUI
import VoltsyCore
import VoltMascot
import BatteryEngines

struct WeeklyRecapView: View {
    let voltState: VoltState
    let weeklyGreenShare: Double
    let streak: Int
    let badges: Int

    private var healthyPercent: Int { Int((weeklyGreenShare * 100).rounded()) }

    var body: some View {
        VStack(spacing: 20) {
            Text("This week with Volt").font(.title2.bold())
            VoltView(state: voltState, size: 160).frame(height: 170)
            Text("You kept me healthy \(healthyPercent)% of the week!")
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)
            HStack(spacing: 28) {
                stat("\(streak)", streak == 1 ? "day streak" : "day streak", "flame.fill", .orange)
                stat("\(badges)", badges == 1 ? "badge" : "badges", "rosette", .yellow)
            }
            Text("voltsy").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: [Color(red: 0.36, green: 0.80, blue: 0.55).opacity(0.18), .clear],
                           startPoint: .top, endPoint: .bottom)
        )
    }

    private func stat(_ value: String, _ label: String, _ icon: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.title2).foregroundStyle(color)
            Text(value).font(.title.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
    }
}
