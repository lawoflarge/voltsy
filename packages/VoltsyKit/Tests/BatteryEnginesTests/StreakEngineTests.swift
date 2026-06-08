// Tests/BatteryEnginesTests/StreakEngineTests.swift
import Testing
@testable import BatteryEngines

@Suite("StreakEngine")
struct StreakEngineTests {
    @Test("all healthy days build the streak and spend no tokens")
    func allHealthy() {
        let r = StreakEngine.compute(dayOutcomes: [true, true, true, true, true], freezeTokens: 1)
        #expect(r.current == 5)
        #expect(r.longest == 5)
        #expect(r.tokensRemaining == 1)
        #expect(r.frozeMostRecentDay == false)
    }

    @Test("a bad day with no token resets the streak but keeps the longest")
    func resetNoToken() {
        let r = StreakEngine.compute(dayOutcomes: [true, true, true, false], freezeTokens: 0)
        #expect(r.current == 0)
        #expect(r.longest == 3)
        #expect(r.frozeMostRecentDay == false)
    }

    @Test("a freeze token preserves the streak through a bad day")
    func freezePreserves() {
        let r = StreakEngine.compute(dayOutcomes: [true, true, true, false], freezeTokens: 1)
        #expect(r.current == 3)
        #expect(r.longest == 3)
        #expect(r.tokensRemaining == 0)
        #expect(r.frozeMostRecentDay == true)
    }

    @Test("empty history is a zero streak")
    func emptyHistory() {
        let r = StreakEngine.compute(dayOutcomes: [], freezeTokens: 2)
        #expect(r.current == 0)
        #expect(r.longest == 0)
        #expect(r.tokensRemaining == 2)
    }
}
