// Tests/BatteryEnginesTests/VoltStateMapperTests.swift
import Testing
import VoltsyCore
@testable import BatteryEngines

@Suite("VoltStateMapper")
struct VoltStateMapperTests {
    private func map(level: Double, state: BatteryChargeState = .unplugged,
                     thermal: ThermalLevel = .nominal, lpm: Bool = false,
                     minutesAtFull: Int = 0, tint: HealthTint = .green) -> VoltState {
        VoltStateMapper.map(level: level, state: state, thermal: thermal,
                            lowPowerMode: lpm, minutesAtFull: minutesAtFull, tint: tint)
    }

    @Test("overheating beats everything, even while charging")
    func overheating() {
        #expect(map(level: 0.5, state: .charging, thermal: .serious).mood == .overheating)
        #expect(map(level: 0.05, thermal: .critical).mood == .overheating)
    }

    @Test("charging beats a low level")
    func chargingBeatsLow() {
        #expect(map(level: 0.05, state: .charging).mood == .charging)
    }

    @Test("sustained full is overcharged; fresh full celebrates")
    func fullStates() {
        #expect(map(level: 1.0, state: .full, minutesAtFull: 90).mood == .overcharged)
        #expect(map(level: 1.0, state: .full, minutesAtFull: 5).mood == .energetic)
    }

    @Test("discharging boundaries: critical / zen / tired / content / energetic")
    func dischargingBoundaries() {
        #expect(map(level: 0.10).mood == .critical)
        #expect(map(level: 0.08, lpm: true).mood == .critical)      // critical beats LPM
        #expect(map(level: 0.25, lpm: true).mood == .zen)           // LPM beats tired
        #expect(map(level: 0.25).mood == .tired)
        #expect(map(level: 0.30).mood == .tired)
        #expect(map(level: 0.50).mood == .content)
        #expect(map(level: 0.85).mood == .energetic)
    }

    @Test("bellyFill clamps and unknown level is neutral")
    func belly() {
        #expect(map(level: 0.42).bellyFill == 0.42)
        #expect(map(level: 1.5).bellyFill == 1.0)
        let unknown = map(level: -1, state: .unknown)
        #expect(unknown.mood == .content)
        #expect(unknown.bellyFill == 0.5)
    }

    @Test("tint passes through")
    func tintPassthrough() {
        #expect(map(level: 0.5, tint: .red).tint == .red)
    }
}
