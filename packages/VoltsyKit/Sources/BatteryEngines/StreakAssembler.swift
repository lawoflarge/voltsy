// Sources/BatteryEngines/StreakAssembler.swift
// Glue between the raw sample time-series and the streak: group samples into calendar
// days, evaluate each day's care health, and hand oldest-first outcomes to StreakEngine.
import Foundation
import VoltsyCore

public enum StreakAssembler {
    /// Outcomes oldest-first (true = a care-healthy day) ready for `StreakEngine.compute`.
    public static func dayOutcomes(from samples: [BatterySample],
                                   calendar: Calendar = .current) -> [Bool] {
        guard !samples.isEmpty else { return [] }
        let byDay = Dictionary(grouping: samples) { calendar.startOfDay(for: $0.timestamp) }
        // A day with no usable (known-level) samples is "no data", not a healthy day —
        // it neither extends nor breaks the streak (avoids a vacuous streak on empty data).
        return byDay.keys.sorted().compactMap { day -> Bool? in
            let known = (byDay[day] ?? []).filter { $0.isLevelKnown }
            guard !known.isEmpty else { return nil }
            return DayHealthEvaluator.evaluate(daySamples: known).isHealthy
        }
    }
}
