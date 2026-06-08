// apps/Voltsy/Sources/Home/HomeView.swift
import SwiftUI
import VoltsyCore
import BatteryEngines

struct HomeView: View {
    @State var model: HomeViewModel

    private var tintColor: Color {
        switch model.voltState.tint { case .green: .green; case .amber: .orange; case .red: .red }
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 5)) { _ in
            VStack(spacing: 24) {
                VoltView(state: model.voltState, size: 200)
                    .frame(height: 210)

                Text(model.voltState.mood.rawValue.capitalized).font(.title2.bold())

                streakRow

                careCard

                Text("On-device estimate from your usage — not Apple's measured cycle count or capacity.")
                    .font(.caption).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).padding(.horizontal)
            }
            .padding()
            .onAppear { model.tick() }
        }
    }

    @ViewBuilder private var careCard: some View {
        VStack(spacing: 4) {
            Text("Battery Care").font(.headline)
            switch model.careScore.confidence {
            case .insufficient:
                Text("Getting to know your battery…").foregroundStyle(.secondary)
            case .estimating:
                // Honest-estimate invariant: never render a fabricated number — only show
                // a score when the engine actually produced one.
                if let value = model.careScore.value {
                    Text("\(value)").font(.system(size: 44, weight: .bold))
                        .foregroundStyle(tintColor)
                } else {
                    Text("Getting to know your battery…").foregroundStyle(.secondary)
                }
            }
        }
        .padding().frame(maxWidth: .infinity)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder private var streakRow: some View {
        if model.streak.current > 0 {
            HStack(spacing: 6) {
                Image(systemName: model.streak.frozeMostRecentDay ? "snowflake" : "flame.fill")
                    .foregroundStyle(model.streak.frozeMostRecentDay ? Color.cyan : Color.orange)
                Text("\(model.streak.current)-day care streak")
                    .font(.subheadline.weight(.semibold))
            }
        } else {
            Label("Keep Volt healthy to start a streak", systemImage: "flame")
                .font(.subheadline).foregroundStyle(.secondary)
        }
    }
}
