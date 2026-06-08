// Sources/BatteryEngines/ChargeEstimateEngine.swift
// Honest charging ETA: derive a charge rate from the most recent contiguous charge run,
// project minutes to a target level. Gated so we never fabricate an ETA from a single
// 5%-quantized reading. Pure — no UIKit/IO — exhaustively unit-tested.
import Foundation
import VoltsyCore

public enum ChargeEstimateEngine {
    /// A charge run must span at least this long before its rate is trusted.
    public static let minimumSpan: TimeInterval = 5 * 60

    /// Charge rate as fraction-of-full per minute (> 0), from the most recent contiguous
    /// charge run. nil when the latest sample is not charging, or the run is too short / flat.
    public static func chargeRatePerMinute(from samples: [BatterySample]) -> Double? {
        let known = samples.filter { $0.isLevelKnown }.sorted { $0.timestamp < $1.timestamp }
        guard known.last?.state == .charging else { return nil }
        guard let run = SessionEngine.sessions(from: samples).last, run.kind == .charge else { return nil }
        guard run.duration >= minimumSpan, run.levelDelta > 0 else { return nil }
        return run.levelDelta / (run.duration / 60)
    }

    /// Estimated whole minutes from the latest known level to `target` (0...1) at the current
    /// charge rate. nil when not charging, already at/above target, or the rate isn't trustworthy.
    public static func minutesToLevel(_ target: Double, from samples: [BatterySample]) -> Int? {
        // Compute the rate first: it early-exits in the common not-charging case before we
        // bother finding the current level (no redundant second filter/sort of the window).
        guard let rate = chargeRatePerMinute(from: samples) else { return nil }
        guard let current = samples.filter({ $0.isLevelKnown })
            .max(by: { $0.timestamp < $1.timestamp })?.level, current < target else { return nil }
        // Round to the nearest minute (the ETA is shown as "≈"): ceil would amplify the
        // tiny floating-point error in the level subtraction into a spurious extra minute.
        return max(1, Int(((target - current) / rate).rounded()))
    }
}
