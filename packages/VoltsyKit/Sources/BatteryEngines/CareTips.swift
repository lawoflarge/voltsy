// Sources/BatteryEngines/CareTips.swift
// Evidence-based, anti-anxiety battery-care coaching (spec F3). General habit advice only —
// no per-device claims, no fear-mongering. Pure content — unit-tested.
import VoltsyCore

public struct CareTip: Identifiable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let body: String
    public let icon: String          // SF Symbol name
    public init(id: String, title: String, body: String, icon: String) {
        self.id = id; self.title = title; self.body = body; self.icon = icon
    }
}

public enum CareTips {
    public static let all: [CareTip] = [
        CareTip(id: "heat", title: "Heat is the #1 enemy",
                body: "Batteries age fastest when hot. Avoid charging under a pillow, in a hot car, or in direct sun — and slip the case off if I'm getting warm.",
                icon: "thermometer.sun.fill"),
        CareTip(id: "middle", title: "Live in the middle",
                body: "Keeping me roughly between 20% and 80% is gentler than topping up to 100% or running to empty. Optimized Charging (or an 80–90% limit) does this for you.",
                icon: "battery.50percent"),
        CareTip(id: "slow", title: "Slow down when you can",
                body: "Fast charging makes heat. When you're not in a hurry, a slower charger is kinder to my battery.",
                icon: "tortoise.fill"),
        CareTip(id: "overnight", title: "Overnight is fine",
                body: "Charging overnight won't \"overcharge\" me — modern iPhones stop at 100%. It's the heat and sitting at 100% for hours that add up, which Optimized Charging avoids.",
                icon: "moon.zzz.fill"),
        CareTip(id: "calibrate", title: "No need to drain to 0%",
                body: "Fully draining to \"calibrate\" is an old myth from older battery types. I actually prefer partial top-ups — deep drains are harder on me.",
                icon: "checkmark.seal.fill"),
        CareTip(id: "cold", title: "Cold isn't great either",
                body: "Very cold temperatures temporarily drop my range and, while charging in freezing cold, can cause lasting harm. Room temperature is my happy place.",
                icon: "snowflake"),
    ]

    /// A tip most relevant to the current state, falling back to the first general tip.
    public static func contextual(thermal: ThermalLevel, lowPowerMode: Bool, level: Double) -> CareTip {
        if thermal >= .serious { return tip("heat") }
        if level >= 0 && level <= 0.10 { return tip("middle") }
        return all[0]
    }

    private static func tip(_ id: String) -> CareTip {
        all.first { $0.id == id } ?? all[0]
    }
}
