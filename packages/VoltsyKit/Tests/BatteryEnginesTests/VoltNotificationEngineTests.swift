import Testing
import VoltsyCore
@testable import BatteryEngines

@Suite("VoltNotificationEngine")
struct VoltNotificationEngineTests {
    @Test func overheatingWinsOverLowBattery() {
        let m = VoltNotificationEngine.message(level: 0.05, state: .unplugged, thermal: .serious,
                                               streak: 0, todayHealthy: false, isEvening: false)
        #expect(m?.kind == .overheating)
    }
    @Test func lowBatteryIncludesPercentWhenUnplugged() {
        let m = VoltNotificationEngine.message(level: 0.08, state: .unplugged, thermal: .nominal,
                                               streak: 0, todayHealthy: false, isEvening: false)
        #expect(m?.kind == .lowBattery)
        #expect(m?.body.contains("8%") == true)
    }
    @Test func noLowBatteryWhileCharging() {
        let m = VoltNotificationEngine.message(level: 0.08, state: .charging, thermal: .nominal,
                                               streak: 0, todayHealthy: false, isEvening: false)
        #expect(m?.kind != .lowBattery)
    }
    @Test func fullChargeNudgeWhenChargingAndHigh() {
        let m = VoltNotificationEngine.message(level: 0.92, state: .charging, thermal: .nominal,
                                               streak: 0, todayHealthy: false, isEvening: false)
        #expect(m?.kind == .fullChargeNudge)
    }
    @Test func streakReminderOnlyInEveningWhenAtRisk() {
        let evening = VoltNotificationEngine.message(level: 0.5, state: .unplugged, thermal: .nominal,
                                                     streak: 12, todayHealthy: false, isEvening: true)
        #expect(evening?.kind == .streakReminder)
        #expect(evening?.body.contains("12-day") == true)
        let day = VoltNotificationEngine.message(level: 0.5, state: .unplugged, thermal: .nominal,
                                                 streak: 12, todayHealthy: false, isEvening: false)
        #expect(day == nil)
    }
    @Test func nothingNoteworthyReturnsNil() {
        let m = VoltNotificationEngine.message(level: 0.5, state: .unplugged, thermal: .nominal,
                                               streak: 0, todayHealthy: true, isEvening: true)
        #expect(m == nil)
    }
}
