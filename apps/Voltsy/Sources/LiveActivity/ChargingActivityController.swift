// apps/Voltsy/Sources/LiveActivity/ChargingActivityController.swift
// Drives the charging Live Activity from the live sample stream: start on plug-in,
// update as the charge/ETA changes, end on unplug. Local updates only (no push).
#if canImport(ActivityKit)
import Foundation
import ActivityKit
import VoltsyCore
import BatteryEngines

@MainActor
final class ChargingActivityController {
    private var activity: Activity<VoltActivityAttributes>?

    func sync(samples: [BatterySample], voltState: VoltState) {
        guard let latest = samples.filter({ $0.isLevelKnown })
            .max(by: { $0.timestamp < $1.timestamp }) else { return }

        switch latest.state {
        case .charging:
            let toFull = latest.level >= 0.8
            let eta = ChargeEstimateEngine.minutesToLevel(toFull ? 1.0 : 0.8, from: samples)
            push(VoltActivityAttributes.ContentState(
                voltState: voltState, percent: latest.percent,
                etaMinutes: eta, targetIsFull: toFull, isComplete: false))
        case .full:
            push(VoltActivityAttributes.ContentState(
                voltState: voltState, percent: 100,
                etaMinutes: nil, targetIsFull: true, isComplete: true))
        case .unplugged, .unknown:
            end()
        }
    }

    private func push(_ content: VoltActivityAttributes.ContentState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        if let activity {
            Task { await activity.update(ActivityContent(state: content, staleDate: nil)) }
        } else {
            activity = try? Activity.request(
                attributes: VoltActivityAttributes(),
                content: ActivityContent(state: content, staleDate: nil))
        }
    }

    private func end() {
        guard let activity else { return }
        let a = activity
        self.activity = nil
        Task { await a.end(nil, dismissalPolicy: .immediate) }
    }
}
#endif
