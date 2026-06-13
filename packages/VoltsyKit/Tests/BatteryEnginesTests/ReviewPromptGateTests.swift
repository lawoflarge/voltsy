// Tests/BatteryEnginesTests/ReviewPromptGateTests.swift
import Testing
@testable import BatteryEngines

@Suite("ReviewPromptGate")
struct ReviewPromptGateTests {
    @Test("asks when a new streak milestone is reached and none asked before")
    func firstMilestone() {
        #expect(ReviewPromptGate.shouldRequest(streak: 3, lastAskedMilestone: nil) == true)
    }

    @Test("does not ask again for an already-asked milestone")
    func sameMilestone() {
        #expect(ReviewPromptGate.shouldRequest(streak: 3, lastAskedMilestone: 3) == false)
    }

    @Test("asks again at the next higher milestone")
    func nextMilestone() {
        #expect(ReviewPromptGate.shouldRequest(streak: 7, lastAskedMilestone: 3) == true)
    }

    @Test("non-milestone streaks never ask")
    func nonMilestone() {
        #expect(ReviewPromptGate.shouldRequest(streak: 5, lastAskedMilestone: 3) == false)
        #expect(ReviewPromptGate.shouldRequest(streak: 0, lastAskedMilestone: nil) == false)
    }
}
