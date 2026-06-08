// Sources/BatteryEngines/Achievements.swift
// Badges from spec §196. Each is earned by a completed day's samples (+ current streak);
// the caller unions earned badges into a persisted unlocked set. Documented thresholds.
import Foundation
import VoltsyCore

public enum Achievement: String, CaseIterable, Sendable, Codable {
    case goldilocks         // kept it in the 20–80% green zone nearly all day (>= 90%)
    case coolCustomer       // a full day without a serious+ thermal reading
    case noDrama            // never deep-discharged that day (min known level >= 10%)
    case nightOwlReformed   // didn't sit plugged at 100% (minutes-at-full < 60)
    case centenarian        // reached a 100-day care streak
}

public enum AchievementsEngine {
    /// Achievements earned by this completed day's samples + the current streak.
    public static func earned(daySamples: [BatterySample], streak: Int) -> Set<Achievement> {
        var out = Set<Achievement>()
        if streak >= 100 { out.insert(.centenarian) }
        let known = daySamples.filter { $0.isLevelKnown }
        guard !known.isEmpty else { return out }      // the rest need real day data
        if GreenZoneEngine.greenShare(daySamples: known) >= 0.90 { out.insert(.goldilocks) }
        if daySamples.allSatisfy({ $0.thermal < .serious }) { out.insert(.coolCustomer) }
        if let minLevel = known.map(\.level).min(), minLevel >= 0.10 { out.insert(.noDrama) }
        if SessionEngine.minutesAtFull(from: daySamples) < 60 { out.insert(.nightOwlReformed) }
        return out
    }
}
