// Sources/BatteryEngines/ChargeAlertEngine.swift
// One-shot charge/discharge/heat alerts decided on the TRANSITION EDGE between two
// consecutive samples, so a held state never re-nags (spec F1; thresholds are Pro-tunable
// per P1). Pure — unit-tested. Copy is shared with VoltNotificationEngine.crossingBody.
import VoltsyCore

public enum ChargeAlertEngine {
    /// The one-shot alert warranted by the transition from `previous` to `current`, or nil.
    /// Fires only on the crossing edge. A nil `previous` (cold start) never fires, so launch
    /// on an already-high/low battery doesn't nag.
    public static func alert(previous: BatterySample?, current: BatterySample,
                             highThreshold: Double = 0.80,
                             lowThreshold: Double = 0.15) -> VoltMessage? {
        guard current.isLevelKnown else { return nil }
        guard let previous else { return nil }

        // Overheating: crossed up into serious thermal.
        if current.thermal >= .serious, previous.thermal < .serious {
            return VoltMessage(kind: .overheating,
                               body: VoltNotificationEngine.crossingBody(kind: .overheating, pct: current.percent))
        }
        // Unplug nudge: charging and crossed up through the high threshold.
        let wasHigh = previous.state == .charging && previous.isLevelKnown && previous.level >= highThreshold
        if current.state == .charging, current.level >= highThreshold, !wasHigh {
            return VoltMessage(kind: .fullChargeNudge,
                               body: VoltNotificationEngine.crossingBody(kind: .fullChargeNudge, pct: current.percent))
        }
        // Low alert: unplugged and crossed down through the low threshold.
        let wasLow = previous.state == .unplugged && previous.isLevelKnown && previous.level <= lowThreshold
        if current.state == .unplugged, current.level <= lowThreshold, !wasLow {
            return VoltMessage(kind: .lowBattery,
                               body: VoltNotificationEngine.crossingBody(kind: .lowBattery, pct: current.percent))
        }
        return nil
    }
}
