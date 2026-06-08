// Tests/BatteryEnginesTests/CareScoreEngineTests.swift
import Testing
import Foundation
import VoltsyCore
@testable import BatteryEngines

@Suite("CareScoreEngine")
struct CareScoreEngineTests {
    private let t0 = Date(timeIntervalSince1970: 1_700_000_000)

    /// Builds `count` clean charge/discharge cycles with 25-min sample spacing so
    /// sessions form under the production 30-min gap threshold. Each discharge drops
    /// 0.80 -> 0.30 (0.50 of a cycle), ending well above the deep-discharge floor.
    private func cycles(_ count: Int, thermal: ThermalLevel) -> [BatterySample] {
        var samples: [BatterySample] = []
        for c in 0..<count {
            let base = Double(c) * 100
            func s(_ m: Double, _ level: Double, _ state: BatteryChargeState) -> BatterySample {
                BatterySample(timestamp: t0.addingTimeInterval((base + m) * 60),
                              level: level, state: state, lowPowerMode: false, thermal: thermal)
            }
            samples.append(s(0, 0.80, .unplugged))
            samples.append(s(25, 0.30, .unplugged))   // discharge session: -0.50, ends at 0.30
            samples.append(s(50, 0.30, .charging))    // kind change ends the discharge session
            samples.append(s(75, 0.80, .charging))    // charge session
        }
        return samples
    }

    @Test("insufficient history gates the value to nil")
    func gating() {
        // one cycle = 0.50 accrued, below the 3-cycle confidence gate
        let score = CareScoreEngine.score(from: cycles(1, thermal: .nominal))
        #expect(score.value == nil)
        if case .insufficient = score.confidence {} else { Issue.record("expected .insufficient") }
    }

    @Test("clean usage past the data threshold scores high and green")
    func cleanHigh() {
        // 7 cycles = 3.5 accrued (clears the 3-cycle gate), no heat / no deep discharge / no dwell
        let score = CareScoreEngine.score(from: cycles(7, thermal: .nominal))
        #expect(score.value != nil)
        #expect((score.value ?? 0) >= 90)
        #expect(score.tint == .green)
    }

    @Test("heat exposure lowers the score and drops it out of the green band")
    func heatHurts() {
        let clean = CareScoreEngine.score(from: cycles(7, thermal: .nominal))
        let hot = CareScoreEngine.score(from: cycles(7, thermal: .critical))
        #expect((hot.value ?? 100) < (clean.value ?? 0))
        #expect(hot.tint != .green)
    }
}
