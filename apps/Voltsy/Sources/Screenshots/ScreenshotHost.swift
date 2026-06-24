// apps/Voltsy/Sources/Screenshots/ScreenshotHost.swift
//
// App Store screenshot harness. NOT shipped to users — only rendered when the app is
// launched with `--capture-screen <id>` (the glow-up capture pipeline in
// scripts/glowup/capture.mjs passes this). Each screen is a deterministic, ad-free,
// light-mode marketing composition built from the SAME components the real app uses
// (VoltView, the green-zone ring, the care card, the paywall perks, the Live Activity
// lock-screen view) with hand-picked delightful state, so captures are stable and on-brand
// regardless of the simulator's battery (which reports -1).
//
// Screens: hero · moods · alert · care · widget · pro
import SwiftUI
import VoltsyCore
import VoltMascot

// Voltsy brand green (#33CC66 family) used for marketing accents.
private let brandGreen = Color(red: 0.20, green: 0.80, blue: 0.40)
private let screenBG = Color(red: 0.965, green: 0.992, blue: 0.976) // faint mint-white app canvas
private let labelInk = Color(red: 0.24, green: 0.40, blue: 0.32)     // legible slate-green for captions/labels

enum CaptureScreen: String, CaseIterable {
    case hero, moods, alert, care, widget, pro
}

/// Reads `--capture-screen <id>` from the launch arguments. Returns nil in normal runs.
enum ScreenshotMode {
    static var requested: CaptureScreen? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "--capture-screen"), i + 1 < args.count else { return nil }
        return CaptureScreen(rawValue: args[i + 1])
    }
}

struct ScreenshotHost: View {
    let screen: CaptureScreen

    var body: some View {
        ZStack {
            screenBG.ignoresSafeArea()
            content
        }
        .environment(\.colorScheme, .light)
        .preferredColorScheme(.light)
    }

    @ViewBuilder private var content: some View {
        switch screen {
        case .hero:   HeroScreen()
        case .moods:  MoodsScreen()
        case .alert:  AlertScreen()
        case .care:   CareScreen()
        case .widget: WidgetScreen()
        case .pro:    ProScreen()
        }
    }
}

// MARK: - Shared bits

private struct VoltTitleBar: View {
    var body: some View {
        Text("Voltsy")
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity)
            .padding(.top, 6)
    }
}

private struct StreakChip: View {
    var days: Int = 12
    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "flame.fill").foregroundStyle(.orange)
            Text("\(days)-day care streak").font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 16).padding(.vertical, 9)
        .background(Color.orange.opacity(0.12), in: Capsule())
    }
}

// MARK: - 1. Hero — meet the buddy

private struct HeroScreen: View {
    private let state = VoltState(mood: .energetic, bellyFill: 0.87, tint: .green)
    var body: some View {
        VStack(spacing: 22) {
            VoltTitleBar()
            Spacer(minLength: 8)

            Text("Hi, I'm Volt 👋")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.secondary)

            ZStack {
                Circle()
                    .trim(from: 0, to: 0.74)
                    .stroke(brandGreen.opacity(0.7), style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 256, height: 256)
                VoltView(state: state, size: 224)
            }
            .frame(height: 270)

            VStack(spacing: 4) {
                Text("87%").font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(brandGreen)
                Text("Energetic").font(.title3.weight(.semibold))
            }

            Text("Healthy and happy — keep it up! 💚")
                .font(.subheadline).foregroundStyle(.secondary)

            Label("~7h 20m left", systemImage: "hourglass")
                .font(.caption).foregroundStyle(.secondary)

            StreakChip()

            Spacer(minLength: 14)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 30)
    }
}

// MARK: - 2. Moods — the reactive character

private struct MoodsScreen: View {
    private let demos: [(String, VoltState)] = [
        ("Energetic", VoltState(mood: .energetic, bellyFill: 0.92, tint: .green)),
        ("Content",   VoltState(mood: .content,   bellyFill: 0.60, tint: .green)),
        ("Charging",  VoltState(mood: .charging,  bellyFill: 0.45, tint: .green)),
        ("Sleepy",    VoltState(mood: .tired,     bellyFill: 0.20, tint: .amber)),
        ("Low",       VoltState(mood: .critical,  bellyFill: 0.06, tint: .red)),
        ("Hot",       VoltState(mood: .overheating, bellyFill: 0.70, tint: .amber)),
        ("Full",      VoltState(mood: .overcharged, bellyFill: 1.0, tint: .green)),
        ("Power Nap", VoltState(mood: .zen,       bellyFill: 0.30, tint: .amber)),
    ]
    private let columns = [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]

    var body: some View {
        VStack(spacing: 16) {
            VoltTitleBar()
            Text("One look tells you how your battery feels")
                .font(.subheadline.weight(.medium)).foregroundStyle(labelInk)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(demos, id: \.0) { item in
                    VStack(spacing: 8) {
                        VoltView(state: item.1, size: 122).frame(height: 130)
                        Text(item.0).font(.callout.weight(.semibold)).foregroundStyle(labelInk)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.white, in: RoundedRectangle(cornerRadius: 22))
                    .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(brandGreen.opacity(0.12), lineWidth: 1))
                }
            }
            .padding(.horizontal, 18)
            Spacer(minLength: 6)
        }
        .padding(.bottom, 24)
    }
}

// MARK: - 3. Alert — know when to unplug (mascot-forward, no redundant callout)

private struct AlertScreen: View {
    var body: some View {
        VStack(spacing: 24) {
            VoltTitleBar()
            Spacer(minLength: 16)

            VoltView(state: VoltState(mood: .content, bellyFill: 0.80, tint: .green), size: 236)
                .frame(height: 250)

            // Primary alert card — the focal "when to unplug" moment.
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "bolt.badge.checkmark.fill")
                        .font(.system(size: 30)).foregroundStyle(brandGreen)
                    Text("Battery at 80%").font(.title.weight(.bold))
                    Spacer()
                }
                Text("Time to unplug — staying here keeps Volt in the healthy zone.")
                    .font(.body).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(22)
            .background(.white, in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).strokeBorder(brandGreen.opacity(0.30), lineWidth: 2))
            .shadow(color: brandGreen.opacity(0.12), radius: 22, y: 10)

            // Secondary low-battery row
            HStack(spacing: 13) {
                Image(systemName: "battery.25").font(.title2).foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Low battery reminder").font(.headline)
                    Text("I'll nudge you before Volt gets too sleepy.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(18)
            .background(Color.orange.opacity(0.10), in: RoundedRectangle(cornerRadius: 20))

            Spacer(minLength: 20)
        }
        .padding(.horizontal, 26)
        .padding(.bottom, 34)
    }
}

// MARK: - 4. Care — the daily habit loop

private struct CareScreen: View {
    var body: some View {
        VStack(spacing: 20) {
            VoltTitleBar()
            Spacer(minLength: 4)

            ZStack {
                Circle()
                    .trim(from: 0, to: 0.78)
                    .stroke(brandGreen.opacity(0.75), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 250, height: 250)
                VoltView(state: VoltState(mood: .content, bellyFill: 0.62, tint: .green), size: 196)
            }
            .frame(height: 262)

            Text("78% in the 20–80% green zone today")
                .font(.subheadline.weight(.medium)).foregroundStyle(labelInk)

            // Care score card
            VStack(spacing: 4) {
                Text("Battery Care").font(.headline)
                Text("92").font(.system(size: 46, weight: .bold)).foregroundStyle(brandGreen)
            }
            .padding(.vertical, 16).frame(maxWidth: .infinity)
            .background(brandGreen.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))

            StreakChip()

            // Badges row
            HStack(spacing: 22) {
                badge("circle.lefthalf.filled", "Goldilocks")
                badge("snowflake", "Cool")
                badge("checkmark.seal.fill", "No Drama")
            }
            .padding(.top, 2)

            Spacer(minLength: 12)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 30)
    }

    private func badge(_ icon: String, _ name: String) -> some View {
        VStack(spacing: 5) {
            Image(systemName: icon).font(.title2).foregroundStyle(brandGreen)
            Text(name).font(.caption.weight(.semibold)).foregroundStyle(labelInk)
        }
    }
}

// MARK: - 5. Widget — lives on your Home Screen

private struct WidgetScreen: View {
    var body: some View {
        ZStack {
            // Soft Home-Screen-style wallpaper
            LinearGradient(colors: [Color(red: 0.74, green: 0.92, blue: 0.82),
                                    Color(red: 0.48, green: 0.80, blue: 0.61)],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer(minLength: 24)

                // Home Screen widget tile (systemSmall look), enlarged
                VStack(spacing: 8) {
                    VoltView(state: VoltState(mood: .content, bellyFill: 0.62, tint: .green), size: 132)
                    Text("Volt · 62%").font(.subheadline.weight(.semibold)).foregroundStyle(labelInk)
                }
                .frame(width: 232, height: 232)
                .background(.white, in: RoundedRectangle(cornerRadius: 46, style: .continuous))
                .shadow(color: .black.opacity(0.18), radius: 24, y: 14)

                liveActivityCard

                Spacer(minLength: 16)

                dock
            }
            .padding(.horizontal, 26)
            .padding(.bottom, 22)
        }
    }

    // Faint dock hint so the mint area reads as an intentional Home Screen.
    private var dock: some View {
        HStack(spacing: 24) {
            ForEach(0..<4, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white.opacity(0.30))
                    .frame(width: 62, height: 62)
            }
        }
        .padding(.vertical, 18).padding(.horizontal, 22)
        .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 34, style: .continuous))
    }

    @ViewBuilder private var liveActivityCard: some View {
        #if canImport(ActivityKit)
        VStack(spacing: 8) {
            ChargingLockScreenView(
                state: .init(voltState: VoltState(mood: .charging, bellyFill: 0.82, tint: .green),
                             percent: 82, etaMinutes: 22, targetIsFull: true, isComplete: false)
            )
            .padding(16)
            .background(.black.opacity(0.88), in: RoundedRectangle(cornerRadius: 26))
            .environment(\.colorScheme, .dark)
            Text("Live Activity while charging").font(.caption.weight(.medium)).foregroundStyle(.black.opacity(0.6))
        }
        #else
        EmptyView()
        #endif
    }
}

// MARK: - 6. Pro — one-time unlock

private struct ProScreen: View {
    private let perks: [(String, String)] = [
        ("bolt.slash.fill", "Zero ads, forever"),
        ("clock.arrow.circlepath", "Full battery history & insights"),
        ("snowflake", "Unlimited Power Nap streak freezes"),
        ("paintpalette.fill", "Premium Volt cosmetics & skins"),
        ("rectangle.3.group.fill", "Deluxe widgets & Live Activity"),
    ]
    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 18)
            VoltView(state: VoltState(mood: .energetic, bellyFill: 1.0, tint: .green), size: 132)
                .frame(height: 146)

            VStack(spacing: 6) {
                Text("Keep Volt happy forever").font(.title.bold())
                    .multilineTextAlignment(.center)
                Text("Pay once. Never see an ad again.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 15) {
                ForEach(perks, id: \.1) { perk in
                    HStack(spacing: 13) {
                        Image(systemName: perk.0).font(.headline).foregroundStyle(brandGreen).frame(width: 26)
                        Text(perk.1).font(.subheadline)
                        Spacer()
                    }
                }
            }
            .padding(18).frame(maxWidth: .infinity)
            .background(brandGreen.opacity(0.08), in: RoundedRectangle(cornerRadius: 20))

            Text("Unlock Pro — €4.99 once")
                .font(.headline).foregroundStyle(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(brandGreen, in: RoundedRectangle(cornerRadius: 16))

            Text("Restore Purchases").font(.subheadline.weight(.semibold)).foregroundStyle(brandGreen)

            Text("One-time purchase, no subscription. Tied to your Apple ID.")
                .font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)

            Spacer(minLength: 16)
        }
        .padding(.horizontal, 26)
    }
}
