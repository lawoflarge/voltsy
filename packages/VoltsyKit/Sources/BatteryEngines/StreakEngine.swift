// Sources/BatteryEngines/StreakEngine.swift
// Pure daily battery-care streak with "Power Nap" freeze tokens: one bad day doesn't
// reset the streak if a token is available to spend. The core retention loop (spec §9).
import Foundation

public struct StreakState: Sendable, Equatable {
    public let current: Int
    public let longest: Int
    public let tokensRemaining: Int
    public let frozeMostRecentDay: Bool

    public init(current: Int, longest: Int, tokensRemaining: Int, frozeMostRecentDay: Bool) {
        self.current = current
        self.longest = longest
        self.tokensRemaining = tokensRemaining
        self.frozeMostRecentDay = frozeMostRecentDay
    }
}

public enum StreakEngine {
    /// `dayOutcomes`: chronological, oldest first; `true` = a care-healthy day.
    /// A bad day breaks the streak unless a freeze token is spent to preserve it.
    public static func compute(dayOutcomes: [Bool], freezeTokens: Int) -> StreakState {
        var current = 0
        var longest = 0
        var tokens = freezeTokens
        var frozeLast = false

        for (idx, healthy) in dayOutcomes.enumerated() {
            let isLast = idx == dayOutcomes.count - 1
            if healthy {
                current += 1
                if isLast { frozeLast = false }
            } else if tokens > 0 {
                tokens -= 1                 // freeze preserves the current streak
                if isLast { frozeLast = true }
            } else {
                current = 0
                if isLast { frozeLast = false }
            }
            longest = max(longest, current)
        }

        return StreakState(current: current, longest: longest,
                           tokensRemaining: tokens, frozeMostRecentDay: frozeLast)
    }
}
