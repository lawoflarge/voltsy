import Foundation

public struct BatterySample: Codable, Sendable, Equatable {
    public let timestamp: Date
    public let level: Double            // 0.0...1.0, or -1 if unknown
    public let state: BatteryChargeState
    public let lowPowerMode: Bool
    public let thermal: ThermalLevel

    public init(timestamp: Date, level: Double, state: BatteryChargeState,
                lowPowerMode: Bool, thermal: ThermalLevel) {
        self.timestamp = timestamp
        self.level = level
        self.state = state
        self.lowPowerMode = lowPowerMode
        self.thermal = thermal
    }

    public var isLevelKnown: Bool { level >= 0 }
    public var percent: Int { isLevelKnown ? Int((level * 100).rounded()) : 0 }
}
