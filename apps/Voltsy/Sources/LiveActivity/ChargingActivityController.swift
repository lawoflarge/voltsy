// apps/Voltsy/Sources/LiveActivity/ChargingActivityController.swift
// Drives the charging Live Activity from the live sample stream: start on plug-in,
// update as the charge/ETA changes, end on unplug. Local updates only (no push).
//
// Concurrency note: `Activity` is not treated as Sendable by the strict-concurrency checker,
// so we never hold it as a main-actor-isolated property. The lifecycle is gated by a MainActor
// `started` flag; update/end run in nonisolated Tasks that fetch the current activity from the
// static `Activity.activities` list, so no main-actor-isolated value crosses an isolation domain.
#if canImport(ActivityKit)
import Foundation
import ActivityKit
import VoltsyCore
import BatteryEngines

@MainActor
final class ChargingActivityController {
    private var started = false

    func sync(samples: [BatterySample], voltState: VoltState) {
        guard let latest = samples.filter({ $0.isLevelKnown })
            .max(by: { $0.timestamp < $1.timestamp }) else { return }

        switch latest.state {
        case .charging:
            let toFull = latest.level >= 0.8
            let eta = ChargeEstimateEngine.minutesToLevel(toFull ? 1.0 : 0.8, from: samples)
            present(VoltActivityAttributes.ContentState(
                voltState: voltState, percent: latest.percent,
                etaMinutes: eta, targetIsFull: toFull, isComplete: false))
        case .full:
            present(VoltActivityAttributes.ContentState(
                voltState: voltState, percent: 100,
                etaMinutes: nil, targetIsFull: true, isComplete: true))
        case .unplugged, .unknown:
            if started { started = false; Self.endAll() }
        }
    }

    private func present(_ content: VoltActivityAttributes.ContentState) {
        if started {
            Self.updateCurrent(content)
        } else if ActivityAuthorizationInfo().areActivitiesEnabled {
            started = (try? Activity.request(
                attributes: VoltActivityAttributes(),
                content: ActivityContent(state: content, staleDate: nil))) != nil
        }
    }

    private static func updateCurrent(_ content: VoltActivityAttributes.ContentState) {
        Task {
            guard let activity = Activity<VoltActivityAttributes>.activities.first else { return }
            await activity.update(ActivityContent(state: content, staleDate: nil))
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
