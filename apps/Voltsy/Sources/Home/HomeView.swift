// apps/Voltsy/Sources/Home/HomeView.swift
import SwiftUI
import StoreKit
import VoltsyCore
import VoltMascot
import BatteryEngines
import Monetization

struct HomeView: View {
    @State var model: HomeViewModel
    @State private var showingRecap = false
    @State private var showingPaywall = false
    @Environment(ProStore.self) private var pro
    @Environment(ConsentManager.self) private var consent
    @Environment(AdGate.self) private var gate
    @Environment(InterstitialAdManager.self) private var interstitial
    @Environment(\.requestReview) private var requestReview

    private var tintColor: Color {
        switch model.voltState.tint { case .green: .green; case .amber: .orange; case .red: .red }
    }

    var body: some View {
        NavigationStack {
        TimelineView(.periodic(from: .now, by: 5)) { _ in
            // Scrolls so the whole column stays reachable at the largest text sizes.
            // Without it the two buttons below the fold fall off an iPhone SE at AX5.
            ScrollView {
            VStack(spacing: 24) {
                ZStack {
                    // "Keep it 20–80%" challenge ring — fills with today's green-zone share.
                    Circle()
                        .trim(from: 0, to: model.greenShareToday)
                        .stroke(tintColor.opacity(0.7),
                                style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 232, height: 232)
                        .animation(.easeInOut, value: model.greenShareToday)
                    VoltView(state: model.voltState, size: 200)
                }
                .frame(height: 240)

                Text(model.voltState.mood.rawValue.capitalized).font(.title2.bold())

                Text(model.caption)
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).padding(.horizontal)

                if let mins = model.minutesLeft {
                    Label("~\(mins / 60)h \(mins % 60)m left", systemImage: "hourglass")
                        .font(.caption).foregroundStyle(.secondary)
                }

                streakRow

                careCard

                achievementsRow

                Button {
                    // Present ONE capped interstitial at this natural navigational break,
                    // then open the recap. Gated on !isPro + consent + the AdGate cap;
                    // silent-degrades to opening the recap directly when no ad is due/ready.
                    if !pro.isPro && consent.canShowAds && gate.canShowInterstitial {
                        gate.recordInterstitial()
                        interstitial.present { showingRecap = true }
                    } else {
                        showingRecap = true
                    }
                } label: {
                    Label("This week with Volt", systemImage: "square.and.arrow.up")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.bordered)

                if !pro.isPro {
                    Button { showingPaywall = true } label: {
                        Label("Go Pro — remove ads forever", systemImage: "sparkles")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.borderedProminent)
                }

                Text("On-device estimate from your usage — not Apple's measured cycle count or capacity.")
                    .font(.caption).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).padding(.horizontal)
            }
            .padding()
            }
            .navigationTitle("Voltsy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        NavigationLink { CareTipsView() } label: { Label("Care Tips", systemImage: "lightbulb") }
                        NavigationLink { ChargeHistoryView(store: model.storeForHistory) } label: { Label("Charge History", systemImage: "chart.xyaxis.line") }
                        NavigationLink { AlertSettingsView(prefs: model.alertPrefs) { showingPaywall = true } } label: { Label("Alerts", systemImage: "bell.badge") }
                        NavigationLink { TrustView() } label: { Label("Honest by design", systemImage: "checkmark.shield") }
                        if consent.privacyOptionsRequired {
                            Button { Task { await consent.presentPrivacyOptions() } } label: {
                                Label("Ad privacy options", systemImage: "hand.raised")
                            }
                        }
                    } label: { Image(systemName: "ellipsis.circle") }
                }
            }
            .onAppear { model.tick(); model.isPro = pro.isPro }
            .onChange(of: pro.isPro) { _, newValue in model.isPro = newValue }
            .onChange(of: model.requestReviewNow) { _, fire in
                if fire { requestReview(); model.clearReviewRequest() }
            }
            .sheet(isPresented: $showingRecap) {
                WeeklyRecapView(voltState: model.voltState,
                                weeklyGreenShare: model.weeklyGreenShare,
                                streak: model.streak.current,
                                badges: model.unlockedAchievements.count)
            }
            .sheet(isPresented: $showingPaywall) { PaywallView(store: pro) }
        }
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

    @ViewBuilder private var achievementsRow: some View {
        if model.unlockedAchievements.isEmpty {
            Label("Earn badges by keeping Volt healthy", systemImage: "rosette")
                .font(.caption).foregroundStyle(.secondary)
        } else {
            HStack(spacing: 16) {
                ForEach(Achievement.allCases.filter { model.unlockedAchievements.contains($0) },
                        id: \.self) { badge in
                    VStack(spacing: 3) {
                        Image(systemName: badgeIcon(badge)).font(.title3)
                        Text(badgeName(badge)).font(.caption2)
                    }
                    .foregroundStyle(.primary)
                }
            }
        }
    }

    private func badgeIcon(_ a: Achievement) -> String {
        switch a {
        case .goldilocks: "circle.lefthalf.filled"
        case .coolCustomer: "snowflake"
        case .noDrama: "checkmark.seal.fill"
        case .nightOwlReformed: "moon.stars.fill"
        case .centenarian: "100.circle.fill"
        }
    }

    private func badgeName(_ a: Achievement) -> String {
        switch a {
        case .goldilocks: "Goldilocks"
        case .coolCustomer: "Cool"
        case .noDrama: "No Drama"
        case .nightOwlReformed: "Night Owl"
        case .centenarian: "100-day"
        }
    }
}
