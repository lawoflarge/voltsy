// Tests/BatteryEnginesTests/ChargeHistoryEngineTests.swift
import Testing
import Foundation
import VoltsyCore
@testable import BatteryEngines

@Suite("ChargeHistoryEngine")
struct ChargeHistoryEngineTests {
    private let t0 = Date(timeIntervalSince1970: 1_700_000_000)
    private func s(_ minutes: Double, _ level: Double) -> BatterySample {
        BatterySample(timestamp: t0.addingTimeInterval(minutes * 60), level: level,
                      state: .unplugged, lowPowerMode: false, thermal: .nominal)
    }

    @Test("empty input yields no points")
    func empty() {
        #expect(ChargeHistoryEngine.points(from: [], since: t0).isEmpty)
    }

    @Test("drops samples before the window and unknown levels")
    func windowed() {
        let samples = [s(-60, 0.9), s(10, 0.5), s(20, -1.0), s(30, 0.4)]
        let pts = ChargeHistoryEngine.points(from: samples, since: t0)
        #expect(pts.count == 2)                       // -60 dropped, -1.0 dropped
        #expect(pts.first?.level == 0.5)
        #expect(pts.last?.level == 0.4)
    }

    @Test("returns samples as-is when under the cap")
    func underCap() {
        let samples = (0..<10).map { s(Double($0), 0.5) }
        #expect(ChargeHistoryEngine.points(from: samples, since: t0, maxPoints: 200).count == 10)
    }

    @Test("downsamples to the cap, preserving first and last")
    func downsampled() {
        let samples = (0..<1000).map { s(Double($0), Double($0) / 1000.0) }
        let pts = ChargeHistoryEngine.points(from: samples, since: t0, maxPoints: 50)
        #expect(pts.count == 50)
        #expect(pts.first?.level == 0.0)
        #expect(abs((pts.last?.level ?? 0) - 0.999) < 1e-9)
    }
}
