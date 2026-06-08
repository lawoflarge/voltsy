// Tests/BatteryEnginesTests/DayHealthEvaluatorTests.swift
import Testing
import Foundation
import VoltsyCore
@testable import BatteryEngines

@Suite("DayHealthEvaluator")
struct DayHealthEvaluatorTests {
    private let t0 = Date(timeIntervalSince1970: 1_700_000_000)
    private func s(_ m: Double, _ l: Double, _ st: BatteryChargeState,
                   _ th: ThermalLevel = .nominal) -> BatterySample {
        BatterySample(timestamp: t0.addingTimeInterval(m * 60), level: l,
                      state: st, lowPowerMode: false, thermal: th)
    }

    @Test("a balanced day with no abuse is healthy")
    func healthy() {
        let day = [s(0, 0.80, .unplugged), s(120, 0.40, .unplugged),
                   s(130, 0.40, .charging), s(240, 0.80, .charging)]
        let h = DayHealthEvaluator.evaluate(daySamples: day)
        #expect(h.isHealthy)
        #expect(h.reasons.isEmpty)
    }

    @Test("draining to empty is unhealthy")
    func empty() {
        let h = DayHealthEvaluator.evaluate(daySamples: [s(0, 0.30, .unplugged), s(60, 0.01, .unplugged)])
        #expect(!h.isHealthy)
        #expect(h.reasons.contains(.drainedToEmpty))
    }

    @Test("hours sitting at 100% is unhealthy")
    func fullDwell() {
        let h = DayHealthEvaluator.evaluate(daySamples: [s(0, 1.0, .full), s(240, 1.0, .full)])
        #expect(h.reasons.contains(.longFullDwell))
    }

    @Test("prolonged overheating is unhealthy")
    func overheat() {
        let h = DayHealthEvaluator.evaluate(daySamples: [s(0, 0.5, .unplugged, .nominal),
                                                         s(40, 0.45, .unplugged, .critical)])
        #expect(h.reasons.contains(.prolongedOverheating))
    }
}
