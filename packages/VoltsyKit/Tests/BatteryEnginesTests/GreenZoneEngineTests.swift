import Testing
import Foundation
import VoltsyCore
@testable import BatteryEngines

@Suite("GreenZoneEngine")
struct GreenZoneEngineTests {
    private func s(_ l: Double) -> BatterySample {
        BatterySample(timestamp: Date(timeIntervalSince1970: 1_700_000_000), level: l,
                      state: .unplugged, lowPowerMode: false, thermal: .nominal)
    }
    @Test func allInZoneIsFull() {
        #expect(GreenZoneEngine.greenShare(daySamples: [s(0.3), s(0.5), s(0.8)]) == 1.0)
    }
    @Test func halfInZone() {
        #expect(GreenZoneEngine.greenShare(daySamples: [s(0.5), s(0.95)]) == 0.5)
    }
    @Test func boundsAreInclusive() {
        #expect(GreenZoneEngine.greenShare(daySamples: [s(0.20), s(0.80)]) == 1.0)
    }
    @Test func emptyOrUnknownIsZero() {
        #expect(GreenZoneEngine.greenShare(daySamples: []) == 0.0)
        #expect(GreenZoneEngine.greenShare(daySamples: [s(-1)]) == 0.0)
    }
    @Test func weeklyAveragesPerDayWithData() {
        var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!
        let d1 = Date(timeIntervalSince1970: 1_700_000_000)
        let d2 = d1.addingTimeInterval(60 * 60 * 24)
        func at(_ t: Date, _ l: Double) -> BatterySample {
            BatterySample(timestamp: t, level: l, state: .unplugged, lowPowerMode: false, thermal: .nominal)
        }
        #expect(GreenZoneEngine.weeklyGreenShare(samples: [at(d1, 0.5), at(d2, 0.95)], calendar: c) == 0.5)
    }
}
