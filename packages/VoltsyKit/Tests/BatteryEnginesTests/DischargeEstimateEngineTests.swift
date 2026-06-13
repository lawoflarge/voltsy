// Tests/BatteryEnginesTests/DischargeEstimateEngineTests.swift
import Testing
import Foundation
import VoltsyCore
@testable import BatteryEngines

@Suite("DischargeEstimateEngine")
struct DischargeEstimateEngineTests {
    private let t0 = Date(timeIntervalSince1970: 1_700_000_000)
    private func s(_ minutes: Double, _ level: Double, _ state: BatteryChargeState) -> BatterySample {
        BatterySample(timestamp: t0.addingTimeInterval(minutes * 60), level: level,
                      state: state, lowPowerMode: false, thermal: .nominal)
    }

    @Test("no rate when the latest sample is not unplugged")
    func notDischarging() {
        let samples = [s(0, 0.50, .charging), s(30, 0.60, .charging)]
        #expect(DischargeEstimateEngine.dischargeRatePerMinute(from: samples) == nil)
        #expect(DischargeEstimateEngine.minutesToEmpty(from: samples) == nil)
    }

    @Test("rate and ETA from a clean discharge run")
    func cleanRun() {
        // 80% → 60% over 40 min → 0.20 lost / 40 = 0.005 fraction/min
        let samples = [s(0, 0.80, .unplugged), s(20, 0.70, .unplugged), s(40, 0.60, .unplugged)]
        let rate = DischargeEstimateEngine.dischargeRatePerMinute(from: samples)
        #expect(rate != nil)
        #expect(abs(rate! - 0.005) < 1e-6)
        // to empty from 60%: 0.60 / 0.005 = 120 min
        #expect(DischargeEstimateEngine.minutesToEmpty(from: samples) == 120)
        // to 50%: (0.60-0.50)/0.005 = 20 min
        #expect(DischargeEstimateEngine.minutesToLevel(0.50, from: samples) == 20)
    }

    @Test("no ETA before the run spans the minimum trustworthy duration")
    func tooShort() {
        let samples = [s(0, 0.80, .unplugged), s(2, 0.78, .unplugged)]
        #expect(DischargeEstimateEngine.dischargeRatePerMinute(from: samples) == nil)
        #expect(DischargeEstimateEngine.minutesToEmpty(from: samples) == nil)
    }

    @Test("no ETA once already at or below the target")
    func alreadyThere() {
        let samples = [s(0, 0.45, .unplugged), s(20, 0.40, .unplugged)]
        #expect(DischargeEstimateEngine.minutesToLevel(0.50, from: samples) == nil)
    }

    @Test("a rising (charging) run yields no discharge rate")
    func rising() {
        let samples = [s(0, 0.40, .charging), s(20, 0.55, .charging)]
        #expect(DischargeEstimateEngine.dischargeRatePerMinute(from: samples) == nil)
    }

    @Test("ETA never reports below 1 minute")
    func neverBelowOne() {
        // fast drain: 80% → 21% over 10 min → 0.059/min; from 21% to 20% is < 1 min → floored to 1
        let samples = [s(0, 0.80, .unplugged), s(10, 0.21, .unplugged)]
        #expect(DischargeEstimateEngine.minutesToLevel(0.20, from: samples) == 1)
    }
}
