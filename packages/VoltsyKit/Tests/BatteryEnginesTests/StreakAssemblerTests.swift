// Tests/BatteryEnginesTests/StreakAssemblerTests.swift
import Testing
import Foundation
import VoltsyCore
@testable import BatteryEngines

@Suite("StreakAssembler")
struct StreakAssemblerTests {
    private var utc: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }
    private func at(_ y: Int, _ mo: Int, _ d: Int, _ h: Int) -> Date {
        utc.date(from: DateComponents(year: y, month: mo, day: d, hour: h))!
    }
    private func s(_ date: Date, _ l: Double, _ st: BatteryChargeState) -> BatterySample {
        BatterySample(timestamp: date, level: l, state: st, lowPowerMode: false, thermal: .nominal)
    }

    @Test("groups by calendar day and flags the bad day, oldest first")
    func grouping() {
        let samples = [
            s(at(2024, 1, 1, 9), 0.80, .unplugged), s(at(2024, 1, 1, 12), 0.45, .unplugged),   // healthy
            s(at(2024, 1, 2, 9), 0.20, .unplugged), s(at(2024, 1, 2, 12), 0.01, .unplugged),   // drained -> bad
            s(at(2024, 1, 3, 9), 0.70, .unplugged), s(at(2024, 1, 3, 12), 0.40, .unplugged),   // healthy
        ]
        #expect(StreakAssembler.dayOutcomes(from: samples, calendar: utc) == [true, false, true])
    }

    @Test("empty input yields no outcomes")
    func emptyInput() {
        #expect(StreakAssembler.dayOutcomes(from: [], calendar: utc).isEmpty)
    }

    @Test("a day with only unknown-level samples is skipped (no data, not a streak day)")
    func skipsNoDataDays() {
        let samples = [
            s(at(2024, 1, 1, 9), 0.80, .unplugged),   // real healthy day
            s(at(2024, 1, 2, 9), -1, .unknown),       // unknown-only day -> skipped
        ]
        #expect(StreakAssembler.dayOutcomes(from: samples, calendar: utc) == [true])
    }
}
