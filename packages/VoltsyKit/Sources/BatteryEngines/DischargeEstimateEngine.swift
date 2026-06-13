// Sources/BatteryEngines/DischargeEstimateEngine.swift
// Honest "time left" estimate: derive a discharge rate from the most recent contiguous
// unplugged run, project minutes down to a target level. Gated so we never fabricate an
// ETA from a single 5%-quantized reading. Mirror of ChargeEstimateEngine. Pure — unit-tested.
import Foundation
import VoltsyCore

public enum DischargeEstimateEngine {
    /// A discharge run must span at least this long before its rate is trusted.
    public static let minimumSpan: TimeInterval = 5 * 60

    /// Discharge rate as fraction-of-full LOST per minute (> 0), from the most recent
    /// contiguous discharge run. nil when the latest sample is not unplugged, or the run
    /// is too short / not actually dropping.
    public static func dischargeRatePerMinute(from samples: [BatterySample]) -> Double? {
        let known = samples.filter { $0.isLevelKnown }.sorted { $0.timestamp < $1.timestamp }
        guard known.last?.state == .unplugged else { return nil }
        guard let run = SessionEngine.sessions(from: samples).last, run.kind == .discharge else { return nil }
        guard run.duration >= minimumSpan, run.levelDelta < 0 else { return nil }
        return -run.levelDelta / (run.duration / 60)
    }

    /// Estimated whole minutes from the latest known level down to `target` (0...1) at the
    /// current discharge rate. nil when not discharging, already at/below target, or the
    /// rate isn't trustworthy.
    public static func minutesToLevel(_ target: Double, from samples: [BatterySample]) -> Int? {
        guard let rate = dischargeRatePerMinute(from: samples) else { return nil }
        guard let current = samples.filter({ $0.isLevelKnown })
            .max(by: { $0.timestamp < $1.timestamp })?.level, current > target else { return nil }
        return max(1, Int(((current - target) / rate).rounded()))
    }

    /// Convenience: estimated whole minutes until empty (target 0).
    public static func minutesToEmpty(from samples: [BatterySample]) -> Int? {
        minutesToLevel(0, from: samples)
    }
}
