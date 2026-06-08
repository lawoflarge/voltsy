import Testing
import Foundation
import VoltsyCore
@testable import BatteryEngines

@Suite("AchievementsEngine")
struct AchievementsEngineTests {
    private func s(_ l: Double, thermal: ThermalLevel = .nominal) -> BatterySample {
        BatterySample(timestamp: Date(timeIntervalSince1970: 1_700_000_000), level: l,
                      state: .unplugged, lowPowerMode: false, thermal: thermal)
    }
    @Test func goldilocksOnlyWhenMostlyGreen() {
        let mixed = [s(0.3), s(0.5), s(0.6), s(0.7), s(0.95)]   // 4/5 = 0.8 < 0.9
        #expect(!AchievementsEngine.earned(daySamples: mixed, streak: 0).contains(.goldilocks))
        let green = [s(0.3), s(0.5), s(0.6), s(0.7)]            // 1.0
        #expect(AchievementsEngine.earned(daySamples: green, streak: 0).contains(.goldilocks))
    }
    @Test func coolCustomerUnlessSeriousThermal() {
        #expect(AchievementsEngine.earned(daySamples: [s(0.5)], streak: 0).contains(.coolCustomer))
        #expect(!AchievementsEngine.earned(daySamples: [s(0.5, thermal: .serious)], streak: 0).contains(.coolCustomer))
    }
    @Test func noDramaUnlessDeepDischarge() {
        #expect(AchievementsEngine.earned(daySamples: [s(0.5), s(0.15)], streak: 0).contains(.noDrama))
        #expect(!AchievementsEngine.earned(daySamples: [s(0.5), s(0.05)], streak: 0).contains(.noDrama))
    }
    @Test func centenarianAtHundredStreak() {
        #expect(AchievementsEngine.earned(daySamples: [], streak: 100).contains(.centenarian))
        #expect(!AchievementsEngine.earned(daySamples: [], streak: 99).contains(.centenarian))
    }
    @Test func emptyDayBelowHundredEarnsNothing() {
        #expect(AchievementsEngine.earned(daySamples: [], streak: 5).isEmpty)
    }
}
