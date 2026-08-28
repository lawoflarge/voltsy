// apps/Voltsy/Sources/Home/HomeViewModel.swift
import Foundation
import VoltsyCore
import BatteryEngines
import BatteryStore
import WidgetKit

@MainActor
@Observable
final class HomeViewModel {
    private let store: BatteryStore
    private(set) var monitor: BatteryMonitor!
    private(set) var voltState: VoltState =
        VoltState(mood: .content, bellyFill: 0.5, tint: .green)
    private(set) var careScore: CareScore =
        CareScore(value: nil, confidence: .insufficient(accruedCycles: 0, needed: 3), tint: .green)
    private(set) var streak: StreakState =
        StreakState(current: 0, longest: 0, tokensRemaining: 1, frozeMostRecentDay: false)
    private(set) var greenShareToday: Double = 0
    private(set) var unlockedAchievements: Set<Achievement> = []
    private(set) var weeklyGreenShare: Double = 0
    private(set) var caption: String = ""
    private(set) var minutesLeft: Int? = nil          // discharge ETA (F5), nil when ungated
    private var previousSample: BatterySample? = nil
    let alertPrefs = AlertPreferences()
    var isPro: Bool = false                            // set by the view from ProStore
    private var lastAskedMilestone: Int? =
        UserDefaults.standard.object(forKey: "voltsy.review.lastMilestone") as? Int
    private(set) var requestReviewNow: Bool = false    // view observes + calls requestReview
    private let notifications = VoltNotifications()
    #if canImport(ActivityKit)
    private let liveActivity = ChargingActivityController()
    #endif

    init(store: BatteryStore) {
        self.store = store
        self.monitor = BatteryMonitor { [weak self] sample in
            self?.ingest(sample)
        }
    }

    func tick() { monitor.refresh() }

    /// Called by VoltsyApp after the ATT prompt — launch prompts must never overlap.
    func requestNotificationPermission() async { await notifications.requestPermissionIfNeeded() }

    private func ingest(_ sample: BatterySample) {
        try? store.append(sample)
        let recent = (try? store.samples(since: Date().addingTimeInterval(-60 * 60 * 24 * 30))) ?? [sample]
        let score = CareScoreEngine.score(from: recent)
        let minutesFull = SessionEngine.minutesAtFull(from: recent)
        voltState = VoltStateMapper.map(level: sample.level, state: sample.state,
                                        thermal: sample.thermal, lowPowerMode: sample.lowPowerMode,
                                        minutesAtFull: minutesFull, tint: score.tint)
        VoltSnapshotStore.write(voltState)              // share with the Home-screen widget
        WidgetCenter.shared.reloadAllTimelines()
        careScore = score
        // Finalize completed days (strictly before today, with data) into the persisted ledger.
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        var progress = store.loadStreakProgress()
        let lastFinal = progress.lastFinalizedDay
        let byDay = Dictionary(grouping: recent.filter { $0.isLevelKnown }) {
            cal.startOfDay(for: $0.timestamp)
        }
        let completed = byDay.keys
            .filter { $0 < today && (lastFinal == nil || $0 > lastFinal!) }
            .sorted()
            .map { (day: $0, healthy: DayHealthEvaluator.evaluate(daySamples: byDay[$0]!).isHealthy) }
        // Pro buys "unlimited Power Nap streak freezes": at most one token can be spent
        // per day and the ledger refills every ISO week, so a weekly capacity of 7 is
        // unlimited in practice. Free stays at the single advertised freeze.
        progress = StreakLedgerEngine.advance(progress, completedDays: completed,
                                              capacity: isPro ? 7 : 1, calendar: cal)
        try? store.saveStreakProgress(progress)

        // Display: finalized streak + provisional +1 if today is already healthy.
        let todaySamples = byDay[today] ?? []
        let todayHealthy = !todaySamples.isEmpty
            && DayHealthEvaluator.evaluate(daySamples: todaySamples).isHealthy
        let displayCurrent = progress.currentStreak + (todayHealthy ? 1 : 0)
        streak = StreakState(current: displayCurrent,
                             longest: max(progress.longestStreak, displayCurrent),
                             tokensRemaining: progress.tokens,
                             frozeMostRecentDay: progress.lastDayFrozen)

        // 20–80% challenge ring (today) + badges (from the recent window + persisted streak).
        greenShareToday = GreenZoneEngine.greenShare(daySamples: byDay[today] ?? [])
        var badges = Set<Achievement>()
        for daySamples in byDay.values {
            badges.formUnion(AchievementsEngine.earned(daySamples: daySamples, streak: displayCurrent))
        }
        unlockedAchievements = badges

        // Weekly recap (last 7 days) + daily evening streak nudge.
        let weekAgo = cal.date(byAdding: .day, value: -7, to: today)!
        weeklyGreenShare = GreenZoneEngine.weeklyGreenShare(
            samples: recent.filter { $0.timestamp >= weekAgo }, calendar: cal)
        notifications.scheduleEveningStreakReminder(streak: displayCurrent)

        #if canImport(ActivityKit)
        liveActivity.sync(samples: recent, voltState: voltState)
        #endif

        // F4 caption + F5 discharge ETA.
        caption = VoltCaption.text(for: voltState.mood)
        minutesLeft = DischargeEstimateEngine.minutesToEmpty(from: recent)

        // F1 one-shot alerts on the transition edge (thresholds per tier, P1).
        let th = alertPrefs.effective(isPro: isPro)
        if let alert = ChargeAlertEngine.alert(previous: previousSample, current: sample,
                                               highThreshold: th.high, lowThreshold: th.low) {
            notifications.fireImmediate(alert)
        }
        previousSample = sample

        // F6 review prompt on a fresh positive streak milestone.
        if ReviewPromptGate.shouldRequest(streak: displayCurrent, lastAskedMilestone: lastAskedMilestone) {
            lastAskedMilestone = displayCurrent
            UserDefaults.standard.set(displayCurrent, forKey: "voltsy.review.lastMilestone")
            requestReviewNow = true
        }
    }

    var storeForHistory: BatteryStore { store }
    func clearReviewRequest() { requestReviewNow = false }
}
