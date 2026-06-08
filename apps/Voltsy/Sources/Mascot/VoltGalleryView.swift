// apps/Voltsy/Sources/Mascot/VoltGalleryView.swift
// Dev-only gallery: renders Volt in every mood at once so we can iterate on the look
// via simulator screenshots without needing real battery states. Not shipped.
import SwiftUI
import VoltsyCore
import VoltMascot

struct VoltGalleryView: View {
    private let demos: [(String, VoltState)] = [
        ("Energetic 90%", VoltState(mood: .energetic, bellyFill: 0.90, tint: .green)),
        ("Content 60%", VoltState(mood: .content, bellyFill: 0.60, tint: .green)),
        ("Charging 45%", VoltState(mood: .charging, bellyFill: 0.45, tint: .green)),
        ("Tired 20%", VoltState(mood: .tired, bellyFill: 0.20, tint: .amber)),
        ("Critical 5%", VoltState(mood: .critical, bellyFill: 0.05, tint: .red)),
        ("Overheating", VoltState(mood: .overheating, bellyFill: 0.70, tint: .amber)),
        ("Overcharged 100%", VoltState(mood: .overcharged, bellyFill: 1.0, tint: .green)),
        ("Zen (LPM) 30%", VoltState(mood: .zen, bellyFill: 0.30, tint: .amber)),
    ]

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 14)]

    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                Text("Volt — mood gallery").font(.headline).padding(.top, 8)
                LazyVGrid(columns: columns, spacing: 18) {
                    ForEach(demos, id: \.0) { item in
                        VStack(spacing: 6) {
                            VoltView(state: item.1, size: 132)
                                .frame(height: 140)
                            Text(item.0).font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .background(Color(white: 1.0), in: RoundedRectangle(cornerRadius: 18))
                    }
                }
                .padding(.horizontal, 12)
            }
            .padding(.bottom, 24)
        }
        .background(Color(red: 0.93, green: 0.95, blue: 0.97))
    }
}
