import Testing
import Foundation
import VoltsyCore
@testable import BatteryEngines

private let utc: Calendar = {
    var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c
}()
private func day(_ y: Int, _ m: Int, _ d: Int) -> Date {
    utc.date(from: DateComponents(year: y, month: m, day: d))!
}
private func weekKey(_ d: Date) -> Int {
    utc.component(.yearForWeekOfYear, from: d) * 100 + utc.component(.weekOfYear, from: d)
}

@Suite("StreakLedgerEngine")
struct StreakLedgerEngineTests {
    @Test func healthyDaysExtendStreakAndSpendNoTokens() {
        let start = StreakProgress(currentStreak: 0, longestStreak: 0, tokens: 1,
                                   lastRefillWeek: 0, lastFinalizedDay: nil, lastDayFrozen: false)
        let days = [(day: day(2026, 6, 1), healthy: true), (day: day(2026, 6, 2), healthy: true)]
        let out = StreakLedgerEngine.advance(start, completedDays: days, capacity: 1, calendar: utc)
        #expect(out.currentStreak == 2)
        #expect(out.longestStreak == 2)
        #expect(out.tokens == 1)
        #expect(out.lastFinalizedDay == day(2026, 6, 2))
    }

    @Test func badDayWithTokenFreezesAndSpends() {
        let start = StreakProgress(currentStreak: 3, longestStreak: 5, tokens: 1,
                                   lastRefillWeek: weekKey(day(2026, 6, 2)),
                                   lastFinalizedDay: day(2026, 6, 1), lastDayFrozen: false)
        let out = StreakLedgerEngine.advance(start, completedDays: [(day(2026, 6, 2), false)],
                                             capacity: 1, calendar: utc)
        #expect(out.currentStreak == 3)
        #expect(out.tokens == 0)
        #expect(out.lastDayFrozen == true)
    }

    @Test func badDayWithoutTokenResets() {
        let start = StreakProgress(currentStreak: 4, longestStreak: 4, tokens: 0,
                                   lastRefillWeek: weekKey(day(2026, 6, 2)),
                                   lastFinalizedDay: day(2026, 6, 1), lastDayFrozen: false)
        let out = StreakLedgerEngine.advance(start, completedDays: [(day(2026, 6, 2), false)],
                                             capacity: 1, calendar: utc)
        #expect(out.currentStreak == 0)
        #expect(out.tokens == 0)
        #expect(out.lastDayFrozen == false)
    }

    @Test func newWeekRefillsTokenToCapacity() {
        let start = StreakProgress(currentStreak: 1, longestStreak: 1, tokens: 0,
                                   lastRefillWeek: weekKey(day(2026, 6, 1)),
                                   lastFinalizedDay: day(2026, 6, 1), lastDayFrozen: false)
        let out = StreakLedgerEngine.advance(start, completedDays: [(day(2026, 6, 8), false)],
                                             capacity: 1, calendar: utc)
        #expect(out.tokens == 0)            // refilled to 1, then spent
        #expect(out.currentStreak == 1)     // frozen, preserved
        #expect(out.lastDayFrozen == true)
    }

    @Test func emptyCompletedDaysIsIdentity() {
        let start = StreakProgress(currentStreak: 7, longestStreak: 9, tokens: 1,
                                   lastRefillWeek: 1, lastFinalizedDay: day(2026, 6, 1),
                                   lastDayFrozen: false)
        let out = StreakLedgerEngine.advance(start, completedDays: [], capacity: 1, calendar: utc)
        #expect(out == start)
    }
}
