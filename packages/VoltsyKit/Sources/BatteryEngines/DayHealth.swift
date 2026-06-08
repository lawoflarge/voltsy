// Sources/BatteryEngines/DayHealth.swift
// Pure classification of a single day's battery samples as "care-healthy" or not.
// Feeds the daily streak. Honest + conservative: only flags abuse we can actually observe.
import Foundation
import VoltsyCore

public struct DayHealth: Sendable, Equatable {
    public enum Reason: String, Sendable, Equatable {
        case drainedToEmpty         // hit ~0%
        case longFullDwell          // sat at 100% for hours
        case prolongedOverheating   // ran hot for a sustained stretch
    }
    public let isHealthy: Bool
    public let reasons: [Reason]

    public init(isHealthy: Bool, reasons: [Reason]) {
        self.isHealthy = isHealthy
        self.reasons = reasons
    }
}

public enum DayHealthEvaluator {
    public static let emptyThreshold = 0.02       // <= 2% counts as drained
    public static let fullDwellMinutes = 180.0    // >= 3h at 100%
    public static let overheatMinutes = 30.0      // >= 30 min at thermal >= serious

    public static func evaluate(daySamples: [BatterySample]) -> DayHealth {
        let sorted = daySamples.filter { $0.isLevelKnown }.sorted { $0.timestamp < $1.timestamp }
        var reasons: [DayHealth.Reason] = []

        if sorted.contains(where: { $0.level <= emptyThreshold }) {
            reasons.append(.drainedToEmpty)
        }

        // Attribute each interval to the state/thermal of its later sample.
        var fullMinutes = 0.0
        var hotMinutes = 0.0
        if sorted.count >= 2 {
            for i in 1..<sorted.count {
                let dt = sorted[i].timestamp.timeIntervalSince(sorted[i - 1].timestamp) / 60
                if sorted[i].state == .full { fullMinutes += dt }
                if sorted[i].thermal >= .serious { hotMinutes += dt }
            }
        }
        if fullMinutes >= fullDwellMinutes { reasons.append(.longFullDwell) }
        if hotMinutes >= overheatMinutes { reasons.append(.prolongedOverheating) }

        return DayHealth(isHealthy: reasons.isEmpty, reasons: reasons)
    }
}
