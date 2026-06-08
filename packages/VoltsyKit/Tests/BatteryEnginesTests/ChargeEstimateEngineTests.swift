// Tests/BatteryEnginesTests/ChargeEstimateEngineTests.swift
import Testing
import Foundation
import VoltsyCore
@testable import BatteryEngines

@Suite("ChargeEstimateEngine")
struct ChargeEstimateEngineTests {
    private let t0 = Date(timeIntervalSince1970: 1_700_000_000)
    private func s(_ minutes: Double, _ level: Double, _ state: BatteryChargeState) -> BatterySample {
        BatterySample(timestamp: t0.addingTimeInterval(minutes * 60), level: level,
                      state: state, lowPowerMode: false, thermal: .nominal)
    }

    @Test("no rate when the latest sample is not charging")
    func notCharging() {
        let samples = [s(0, 0.80, .unplugged), s(30, 0.75, .unplugged)]
        #expect(ChargeEstimateEngine.chargeRatePerMinute(from: samples) == nil)
        #expect(ChargeEstimateEngine.minutesToLevel(0.8, from: samples) == nil)
    }

    @Test("rate and ETA from a clean charge run")
    func cleanRun() {
        // 30% → 50% over 40 min → 0.20/40 = 0.005 fraction/min
        let samples = [s(0, 0.30, .charging), s(20, 0.40, .charging), s(40, 0.50, .charging)]
        let rate = ChargeEstimateEngine.chargeRatePerMinute(from: samples)
        #expect(rate != nil)
        #expect(abs(rate! - 0.005) < 1e-6)
        // to 80%: (0.80-0.50)/0.005 = 60 min
        #expect(ChargeEstimateEngine.minutesToLevel(0.8, from: samples) == 60)
        // to full: (1.0-0.50)/0.005 = 100 min
        #expect(ChargeEstimateEngine.minutesToLevel(1.0, from: samples) == 100)
    }

    @Test("no ETA before the run spans the minimum trustworthy duration")
    func tooShort() {
        let samples = [s(0, 0.30, .charging), s(2, 0.35, .charging)] // 2-min span
        #expect(ChargeEstimateEngine.chargeRatePerMinute(from: samples) == nil)
        #expect(ChargeEstimateEngine.minutesToLevel(0.8, from: samples) == nil)
    }

    @Test("no ETA once already at or above the target")
    func alreadyThere() {
        let samples = [s(0, 0.78, .charging), s(20, 0.85, .charging)]
        #expect(ChargeEstimateEngine.minutesToLevel(0.8, from: samples) == nil)
    }

    @Test("full battery yields no charging rate")
    func full() {
        let samples = [s(0, 0.98, .charging), s(20, 1.0, .full)]
        #expect(ChargeEstimateEngine.chargeRatePerMinute(from: samples) == nil)
    }

    @Test("only the most recent charge run after a gap is used")
    func recentRunAfterGap() {
        // old fast run (0.03/min), a >30-min gap, then a slower recent run whose own
        // samples stay within the 30-min gap threshold (else it would split too).
        let samples = [s(0, 0.20, .charging), s(10, 0.50, .charging),   // old run
                       s(60, 0.50, .charging), s(85, 0.65, .charging), s(110, 0.80, .charging)]
        let rate = ChargeEstimateEngine.chargeRatePerMinute(from: samples)
        #expect(rate != nil)
        #expect(abs(rate! - (0.30 / 50)) < 1e-6) // 0.006, from the recent run only
    }

    @Test("ETA never reports below 1 minute")
    func neverBelowOne() {
        // fast charge: 20% → 79% over 10 min → 0.059/min; from 79% to 80% is < 1 min → floored to 1
        let samples = [s(0, 0.20, .charging), s(10, 0.79, .charging)]
        #expect(ChargeEstimateEngine.minutesToLevel(0.8, from: samples) == 1)
    }
}
