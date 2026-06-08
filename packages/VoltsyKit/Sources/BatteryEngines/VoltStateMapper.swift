// Sources/BatteryEngines/VoltStateMapper.swift
import VoltsyCore

public enum VoltStateMapper {
    public static let overchargedThresholdMinutes = 60
    public static let criticalCeiling = 0.10
    public static let tiredCeiling = 0.30
    public static let healthyFloor = 0.80

    public static func map(level: Double, state: BatteryChargeState, thermal: ThermalLevel,
                           lowPowerMode: Bool, minutesAtFull: Int, tint: HealthTint) -> VoltState {
        guard level >= 0 else {
            return VoltState(mood: .content, bellyFill: 0.5, tint: tint)
        }
        let belly = min(1.0, max(0.0, level))
        let mood: VoltMood

        if thermal >= .serious {
            mood = .overheating
        } else if state == .charging {
            mood = .charging
        } else if state == .full && minutesAtFull >= overchargedThresholdMinutes {
            mood = .overcharged
        } else if state == .full {
            mood = .energetic
        } else if level <= criticalCeiling {
            mood = .critical
        } else if lowPowerMode {
            mood = .zen
        } else if level <= tiredCeiling {
            mood = .tired
        } else if level < healthyFloor {
            mood = .content
        } else {
            mood = .energetic
        }
        return VoltState(mood: mood, bellyFill: belly, tint: tint)
    }
}
