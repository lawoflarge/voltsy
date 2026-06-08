// apps/Voltsy/Sources/LiveActivity/ChargingActivityController.swift
// Drives the charging Live Activity from the live sample stream: start on plug-in,
// update as the charge/ETA changes, end on unplug. Local updates only (no push).
//
// State is read from ActivityKit itself (`Activity.activities`), not a private flag, so the
// controller self-heals: it never spawns a duplicate after an app relaunch mid-charge, and a
// user-dismissed activity is re-created on the next charging sample rather than going silent.
//
// Concurrency: `Activity` is not treated as Sendable by the strict-concurrency checker, so we
// never let a main-actor-isolated `Activity` value cross into a nonisolated `update`/`end` call.
// Existence is checked via a Bool (`activities.isEmpty`); the activity itself is fetched *inside*
// the nonisolated Task. sync() is MainActor-serialized and samples arrive seconds apart, so the
// fire-and-forget update/end Tasks cannot realistically interleave — no serial queue needed for v1.
#if canImport(ActivityKit)
import Foundation
import ActivityKit
import VoltsyCore
import BatteryEngines

@MainActor
final class ChargingActivityController {
    /// If no update arrives within this window (e.g. the app is killed mid-charge), the system
    /// marks the activity stale and dims it — honest about not having fresh data.
    private static let staleAfter: TimeInterval = 60 * 60

    func sync(samples: [BatterySample], voltState: VoltState) {
        guard let latest = samples.filter({ $0.isLevelKnown })
            .max(by: { $0.timestamp < $1.timestamp }) else { return }

        switch latest.state {
        case .charging:
            let toFull = latest.level >= 0.8
            let eta = ChargeEstimateEngine.minutesToLevel(toFull ? 1.0 : 0.8, from: samples)
            present(VoltActivityAttributes.ContentState(
                voltState: voltState, percent: latest.percent,
                etaMinutes: eta, targetIsFull: toFull, isComplete: false),
                startIfAbsent: true)
        case .full:
            present(VoltActivityAttributes.ContentState(
                voltState: voltState, percent: 100,
                etaMinutes: nil, targetIsFull: true, isComplete: true),
                startIfAbsent: false)   // don't spawn a banner for an already-full battery
        case .unplugged, .unknown:
            Self.endAll()
        }
    }

    private func present(_ content: VoltActivityAttributes.ContentState, startIfAbsent: Bool) {
        if !Activity<VoltActivityAttributes>.activities.isEmpty {
            Self.updateCurrent(content)
        } else if startIfAbsent, ActivityAuthorizationInfo().areActivitiesEnabled {
            _ = try? Activity.request(
                attributes: VoltActivityAttributes(),
                content: ActivityContent(state: content, staleDate: Self.stale()))
        }
    }

    private static func stale() -> Date { Date().addingTimeInterval(staleAfter) }

    private static func updateCurrent(_ content: VoltActivityAttributes.ContentState) {
        let staleDate = stale()
        Task {
            guard let activity = Activity<VoltActivityAttributes>.activities.first else { return }
            await activity.update(ActivityContent(state: content, staleDate: staleDate))
        }
    }

    private static func endAll() {
        Task {
            for activity in Activity<VoltActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
#endif
