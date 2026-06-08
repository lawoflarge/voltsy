// Tests/BatteryEnginesTests/SessionEngineTests.swift
import Testing
import Foundation
import VoltsyCore
@testable import BatteryEngines

@Suite("SessionEngine")
struct SessionEngineTests {
    private let t0 = Date(timeIntervalSince1970: 1_700_000_000)
    private func s(_ minutes: Double, _ level: Double, _ state: BatteryChargeState) -> BatterySample {
        BatterySample(timestamp: t0.addingTimeInterval(minutes * 60), level: level,
                      state: state, lowPowerMode: false, thermal: .nominal)
    }

    @Test("empty and single-sample inputs yield no sessions")
    func sparse() {
        #expect(SessionEngine.sessions(from: []).isEmpty)
        #expect(SessionEngine.sessions(from: [s(0, 0.5, .unplugged)]).isEmpty)
    }

    @Test("a clean discharge run is one discharge session with %/h rate")
    func discharge() {
        let samples = [s(0, 0.80, .unplugged), s(30, 0.75, .unplugged), s(60, 0.70, .unplugged)]
        let sessions = SessionEngine.sessions(from: samples)
        #expect(sessions.count == 1)
        #expect(sessions[0].kind == .discharge)
        // 10% over 1h = -10 %/h
        #expect(abs(sessions[0].ratePerHour - (-10)) < 0.001)
    }

    @Test("a charge then discharge produces two sessions")
    func twoSessions() {
        let samples = [s(0, 0.40, .charging), s(20, 0.60, .charging),
                       s(40, 0.58, .unplugged), s(70, 0.50, .unplugged)]
        let sessions = SessionEngine.sessions(from: samples)
        #expect(sessions.count == 2)
        #expect(sessions[0].kind == .charge)
        #expect(sessions[1].kind == .discharge)
    }

    @Test("a large time gap splits a session")
    func gapSplits() {
        let samples = [s(0, 0.80, .unplugged), s(20, 0.76, .unplugged),
                       s(400, 0.40, .unplugged), s(420, 0.36, .unplugged)] // 380-min gap
        let sessions = SessionEngine.sessions(from: samples)
        #expect(sessions.count == 2)
    }

    @Test("minutesAtFull counts the most recent contiguous full tail")
    func minutesAtFull() {
        let samples = [s(0, 0.98, .charging), s(10, 1.0, .full), s(70, 1.0, .full)]
        let m = SessionEngine.minutesAtFull(from: samples)
        #expect(m == 60)
    }
}
