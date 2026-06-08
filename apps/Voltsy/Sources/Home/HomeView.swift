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
                // Placeholder "Volt" — replaced by the real vector mascot in Plan 2.
                ZStack(alignment: .bottom) {
                    RoundedRectangle(cornerRadius: 28).stroke(tintColor, lineWidth: 4)
                    RoundedRectangle(cornerRadius: 24)
                        .fill(tintColor.opacity(0.5))
                        .frame(height: 180 * model.voltState.bellyFill)
                        .padding(6)
                }
                .frame(width: 120, height: 180)
                .overlay(Text(emoji(model.voltState.mood)).font(.system(size: 48)))

                Text(model.voltState.mood.rawValue.capitalized).font(.title2.bold())

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
                Text("\(model.careScore.value ?? 0)").font(.system(size: 44, weight: .bold))
                    .foregroundStyle(tintColor)
            }
        }
        .padding().frame(maxWidth: .infinity)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
    }

    private func emoji(_ mood: VoltMood) -> String {
        switch mood {
        case .energetic: "😄"; case .content: "🙂"; case .tired: "🥱"; case .critical: "😵"
        case .charging: "😋"; case .overcharged: "🤢"; case .overheating: "🥵"; case .zen: "😌"
        }
    }
}
