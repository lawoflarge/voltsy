// Tests/BatteryEnginesTests/CareScoreEngineTests.swift
import Testing
import Foundation
import VoltsyCore
@testable import BatteryEngines

@Suite("CareScoreEngine")
struct CareScoreEngineTests {
    private let t0 = Date(timeIntervalSince1970: 1_700_000_000)
    private func s(_ minutes: Double, _ level: Double, _ state: BatteryChargeState,
                   _ thermal: ThermalLevel = .nominal) -> BatterySample {
        BatterySample(timestamp: t0.addingTimeInterval(minutes * 60), level: level,
                      state: state, lowPowerMode: false, thermal: thermal)
    }

    @Test("insufficient history gates the value to nil")
    func gating() {
        let score = CareScoreEngine.score(from: [s(0, 0.8, .unplugged), s(30, 0.78, .unplugged)])
        #expect(score.value == nil)
        if case .insufficient = score.confidence {} else { Issue.record("expected .insufficient") }
    }

    @Test("clean usage past the data threshold scores high and green")
    func cleanHigh() {
        // three full-ish discharge cycles, no heat, no deep discharge, no overcharge dwell
        var samples: [BatterySample] = []
        for cycle in 0..<3 {
            let base = Double(cycle) * 600
            samples.append(s(base, 0.80, .unplugged))
            samples.append(s(base + 120, 0.30, .unplugged))
            samples.append(s(base + 130, 0.30, .charging))
            samples.append(s(base + 240, 0.80, .charging))
        }
        let score = CareScoreEngine.score(from: samples)
        #expect(score.value != nil)
        #expect((score.value ?? 0) >= 90)
        #expect(score.tint == .green)
    }

    @Test("heavy heat exposure lowers the score and reddens the tint")
    func heatHurts() {
        var samples: [BatterySample] = []
        for cycle in 0..<3 {
            let base = Double(cycle) * 600
            samples.append(s(base, 0.80, .unplugged, .critical))
            samples.append(s(base + 300, 0.30, .unplugged, .critical)) // 300 min hot per cycle
            samples.append(s(base + 310, 0.30, .charging, .critical))
            samples.append(s(base + 600, 0.80, .charging, .critical))
        }
        let score = CareScoreEngine.score(from: samples)
        #expect((score.value ?? 100) < 50)
        #expect(score.tint == .red)
    }
}
