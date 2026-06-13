// apps/Voltsy/Sources/Trust/TrustView.swift
// F2 — turns the iOS limitation into a trust asset. No fake numbers; points to Settings.
import SwiftUI

struct TrustView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Label("Why Volt never shows a \"battery health %\"", systemImage: "checkmark.shield.fill")
                    .font(.title3.bold())

                row("Apple keeps it private",
                    "iOS doesn't let any third-party app read your real battery health, cycle count, or capacity. Apps that show those numbers are guessing — and the guesses are often wrong.")
                row("Where the real number lives",
                    "Your true Battery Health is in Settings → Battery → Battery Health & Charging. That's the one to trust.")
                row("Why my % can differ by a few points",
                    "Since iOS 17, apps only read the level in ~5% steps, so I may show 80% while the status bar shows 78%. That's the OS rounding, not a bug.")
                row("What I do instead",
                    "I give honest, on-device estimates and gentle care habits — and I tell you when I'm unsure rather than inventing a number.")

                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Label("Open Settings", systemImage: "gear")
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)
            }
            .padding()
        }
        .navigationTitle("Honest by design")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Text(body).font(.subheadline).foregroundStyle(.secondary)
        }
    }
}
