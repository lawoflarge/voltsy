// Sources/BatteryEngines/VoltNotification.swift
// Volt-voiced push copy (spec §199): soft, behavior-rewarding nudges. This PURE engine
// only selects the single most relevant message for a context; the app-side scheduler
// owns permission, timing, and frequency capping. Never claims real battery health.
import Foundation
import VoltsyCore

public struct VoltMessage: Sendable, Equatable {
    public enum Kind: String, Sendable, Equatable {
        case overheating, lowBattery, fullChargeNudge, streakReminder
    }
    public let kind: Kind
    public let body: String
    public init(kind: Kind, body: String) { self.kind = kind; self.body = body }
}

public enum VoltNotificationEngine {
    /// The most relevant nudge for this moment, or nil if nothing is worth a notification.
    /// Priority: overheating > low battery > top-it-off (20–80%) > streak reminder.
    public static func message(level: Double, state: BatteryChargeState, thermal: ThermalLevel,
                               streak: Int, todayHealthy: Bool, isEvening: Bool) -> VoltMessage? {
        let pct = level >= 0 ? Int((level * 100).rounded()) : 0
        if thermal >= .serious {
            return VoltMessage(kind: .overheating, body: crossingBody(kind: .overheating, pct: pct))
        }
        if state == .unplugged, level >= 0, level <= 0.15 {
            return VoltMessage(kind: .lowBattery, body: crossingBody(kind: .lowBattery, pct: pct))
        }
        if state == .charging, level >= 0.80 {
            return VoltMessage(kind: .fullChargeNudge, body: crossingBody(kind: .fullChargeNudge, pct: pct))
        }
        if isEvening, streak > 0, !todayHealthy {
            return VoltMessage(kind: .streakReminder, body: "Don't let our \(streak)-day streak fizzle — keep me happy today! 🔥")
        }
        return nil
    }

    /// Volt-voiced copy for the three battery-crossing alert kinds. Shared by the
    /// scheduler message above and ChargeAlertEngine, so the wording lives in one place.
    public static func crossingBody(kind: VoltMessage.Kind, pct: Int) -> String {
        switch kind {
        case .overheating:     return "Phew, I'm getting toasty. Give me a breather? 🥵"
        case .lowBattery:      return "I'm fading… \(pct)% and dropping. Got a charger? 🔌"
        case .fullChargeNudge: return "I'm full at \(pct)%. Unplug me to keep my battery young! ✨"
        case .streakReminder:  return ""   // streak copy is contextual; handled in message(...)
        }
    }
}
