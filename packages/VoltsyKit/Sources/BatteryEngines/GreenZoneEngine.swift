// Sources/BatteryEngines/GreenZoneEngine.swift
// "Keep it 20–80%" challenge (spec §194): the share of a day spent in the healthy band,
// and a weekly average for the recap card. Pure, sample-based.
import Foundation
import VoltsyCore

public enum GreenZoneEngine {
    public static let lower = 0.20
    public static let upper = 0.80

    /// Fraction (0...1) of a day's known-level samples within the healthy [20%, 80%] band.
    public static func greenShare(daySamples: [BatterySample]) -> Double {
        let known = daySamples.filter { $0.isLevelKnown }
        guard !known.isEmpty else { return 0 }
        let inZone = known.filter { $0.level >= lower && $0.level <= upper }.count
        return Double(inZone) / Double(known.count)
    }

    /// Average green share across days that have data ("kept me healthy X% this week").
    public static func weeklyGreenShare(samples: [BatterySample],
                                        calendar: Calendar = .current) -> Double {
        let byDay = Dictionary(grouping: samples.filter { $0.isLevelKnown }) {
            calendar.startOfDay(for: $0.timestamp)
        }
        guard !byDay.isEmpty else { return 0 }
        let shares = byDay.values.map { greenShare(daySamples: $0) }
        return shares.reduce(0, +) / Double(shares.count)
    }
}
