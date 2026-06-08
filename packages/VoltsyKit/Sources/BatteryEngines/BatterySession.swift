// Sources/BatteryEngines/BatterySession.swift
import Foundation
import VoltsyCore

public struct BatterySession: Sendable, Equatable {
    public enum Kind: Sendable, Equatable { case charge, discharge }
    public let kind: Kind
    public let start: Date
    public let end: Date
    public let startLevel: Double
    public let endLevel: Double

    public var duration: TimeInterval { end.timeIntervalSince(start) }
    public var levelDelta: Double { endLevel - startLevel }
    /// Percentage points per hour (signed). 0 if duration is non-positive.
    public var ratePerHour: Double {
        let hours = duration / 3600
        guard hours > 0 else { return 0 }
        return (levelDelta * 100) / hours
    }
}
