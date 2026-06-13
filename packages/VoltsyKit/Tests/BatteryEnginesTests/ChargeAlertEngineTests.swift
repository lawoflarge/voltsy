// Tests/BatteryEnginesTests/ChargeAlertEngineTests.swift
import Testing
import Foundation
import VoltsyCore
@testable import BatteryEngines

@Suite("ChargeAlertEngine")
struct ChargeAlertEngineTests {
    private let t0 = Date(timeIntervalSince1970: 1_700_000_000)
    private func s(_ level: Double, _ state: BatteryChargeState, _ thermal: ThermalLevel = .nominal) -> BatterySample {
        BatterySample(timestamp: t0, level: level, state: state, lowPowerMode: false, thermal: thermal)
    }

    @Test("fires the unplug nudge when crossing up through the high threshold while charging")
    func crossHigh() {
        let prev = s(0.78, .charging), cur = s(0.82, .charging)
        let msg = ChargeAlertEngine.alert(previous: prev, current: cur)
        #expect(msg?.kind == .fullChargeNudge)
    }

    @Test("does not re-fire while held above the high threshold")
    func heldHigh() {
        let prev = s(0.82, .charging), cur = s(0.85, .charging)
        #expect(ChargeAlertEngine.alert(previous: prev, current: cur) == nil)
    }

    @Test("fires the low alert when crossing down through the low threshold while unplugged")
    func crossLow() {
        let prev = s(0.18, .unplugged), cur = s(0.13, .unplugged)
        #expect(ChargeAlertEngine.alert(previous: prev, current: cur)?.kind == .lowBattery)
    }

    @Test("does not re-fire while held below the low threshold")
    func heldLow() {
        let prev = s(0.13, .unplugged), cur = s(0.10, .unplugged)
        #expect(ChargeAlertEngine.alert(previous: prev, current: cur) == nil)
    }

    @Test("fires overheating when crossing into serious thermal")
    func crossHeat() {
        let prev = s(0.50, .unplugged, .fair), cur = s(0.50, .unplugged, .serious)
        #expect(ChargeAlertEngine.alert(previous: prev, current: cur)?.kind == .overheating)
    }

    @Test("custom thresholds shift the firing point")
    func customThresholds() {
        // With a 90% high threshold, crossing 82% must NOT fire.
        let prev = s(0.78, .charging), cur = s(0.82, .charging)
        #expect(ChargeAlertEngine.alert(previous: prev, current: cur, highThreshold: 0.90) == nil)
        // …but crossing 92% does.
        let prev2 = s(0.88, .charging), cur2 = s(0.92, .charging)
        #expect(ChargeAlertEngine.alert(previous: prev2, current: cur2, highThreshold: 0.90)?.kind == .fullChargeNudge)
    }

    @Test("a nil previous (cold start) does not spuriously fire on a held state")
    func coldStartHeld() {
        // First sample already high — treat as no transition (avoid nagging on launch).
        #expect(ChargeAlertEngine.alert(previous: nil, current: s(0.95, .charging)) == nil)
    }

    @Test("unknown level never fires")
    func unknown() {
        #expect(ChargeAlertEngine.alert(previous: s(0.5, .unplugged), current: s(-1, .unknown)) == nil)
    }
}
