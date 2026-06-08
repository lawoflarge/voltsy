// Tests/VoltsyCoreTests/BatterySampleTests.swift
import Testing
import Foundation
@testable import VoltsyCore

@Suite("BatterySample")
struct BatterySampleTests {
    @Test("percent rounds the 0...1 level to a whole number")
    func percentRounds() {
        let s = BatterySample(timestamp: Date(timeIntervalSince1970: 0), level: 0.474,
                              state: .unplugged, lowPowerMode: false, thermal: .nominal)
        #expect(s.percent == 47)
    }

    @Test("isLevelKnown is false for the -1 sentinel")
    func unknownLevel() {
        let s = BatterySample(timestamp: Date(timeIntervalSince1970: 0), level: -1,
                              state: .unknown, lowPowerMode: false, thermal: .nominal)
        #expect(s.isLevelKnown == false)
        #expect(s.percent == 0)
    }

    @Test("ThermalLevel is comparable by severity")
    func thermalComparable() {
        #expect(ThermalLevel.serious > ThermalLevel.fair)
        #expect(ThermalLevel.nominal < ThermalLevel.critical)
    }
}
