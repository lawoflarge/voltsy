// apps/Voltsy/Sources/Settings/AlertSettingsView.swift
// P1 — Pro users tune the unplug/low thresholds; Free sees the locked defaults + a Pro CTA.
import SwiftUI
import CrossPromotionUI
import Monetization

struct AlertSettingsView: View {
    @State private var promotions = AppPromotions.makeStore()
    var isActive = true
    @Bindable var prefs: AlertPreferences
    @Environment(ProStore.self) private var pro
    var onUpgrade: () -> Void

    var body: some View {
        PromotionViewport { viewport in
        Form {
            Section {
                Stepper("Unplug nudge at \(prefs.highPercent)%",
                        value: $prefs.highPercent, in: 50...100, step: 5)
                    .disabled(!pro.isPro)
                Stepper("Low alert at \(prefs.lowPercent)%",
                        value: $prefs.lowPercent, in: 5...40, step: 5)
                    .disabled(!pro.isPro)
            } header: {
                Text("Charge alerts")
            } footer: {
                Text("Best-effort nudges — iOS can't guarantee a background alarm at an exact level, so think of these as friendly reminders, not a hard stop.")
            }

            if let promotions {
                AppPromotionSection(store: promotions, viewport: isActive ? viewport : .zero)
            }

            if !pro.isPro {
                Section {
                    Button { onUpgrade() } label: {
                        Label("Customize thresholds with Pro", systemImage: "sparkles")
                    }
                }
            }
        }
        }
        .promotionLifecycle(promotions, isActive: isActive)
        .navigationTitle("Alerts")
        .navigationBarTitleDisplayMode(.inline)
    }
}
