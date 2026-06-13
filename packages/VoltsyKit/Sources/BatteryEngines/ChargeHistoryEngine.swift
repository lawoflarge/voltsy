// Sources/BatteryEngines/ChargeHistoryEngine.swift
// Downsample stored battery samples into chart points for the history graph. Honestly the
// CHARGE LEVEL over time — never "capacity"/"health". Pure — unit-tested.
import Foundation
import VoltsyCore

public struct ChargePoint: Sendable, Equatable, Identifiable {
    public let timestamp: Date
    public let level: Double          // 0...1
    public var id: Date { timestamp }
    public init(timestamp: Date, level: Double) {
        self.timestamp = timestamp
        self.level = level
    }
}

public enum ChargeHistoryEngine {
    /// Known-level samples at or after `since`, ascending, evenly downsampled to at most
    /// `maxPoints` (first and last always kept). Empty when there are no known samples.
    public static func points(from samples: [BatterySample], since: Date,
                              maxPoints: Int = 200) -> [ChargePoint] {
        let known = samples
            .filter { $0.isLevelKnown && $0.timestamp >= since }
            .sorted { $0.timestamp < $1.timestamp }
            .map { ChargePoint(timestamp: $0.timestamp, level: $0.level) }
        let n = known.count
        guard n > maxPoints, maxPoints >= 2 else { return known }
        return (0..<maxPoints).map { i in
            let pos = Int((Double(i) * Double(n - 1) / Double(maxPoints - 1)).rounded())
            return known[pos]
        }
    }
}
