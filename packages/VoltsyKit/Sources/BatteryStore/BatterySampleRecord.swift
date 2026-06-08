// Sources/BatteryStore/BatterySampleRecord.swift
import Foundation
import SwiftData
import VoltsyCore

@Model
public final class BatterySampleRecord {
    public var timestamp: Date
    public var level: Double
    public var stateRaw: String
    public var lowPowerMode: Bool
    public var thermalRaw: Int

    public init(_ sample: BatterySample) {
        self.timestamp = sample.timestamp
        self.level = sample.level
        self.stateRaw = sample.state.rawValue
        self.lowPowerMode = sample.lowPowerMode
        self.thermalRaw = sample.thermal.rawValue
    }

    public func toSample() -> BatterySample {
        BatterySample(timestamp: timestamp, level: level,
                      state: BatteryChargeState(rawValue: stateRaw) ?? .unknown,
                      lowPowerMode: lowPowerMode,
                      thermal: ThermalLevel(rawValue: thermalRaw) ?? .nominal)
    }
}
