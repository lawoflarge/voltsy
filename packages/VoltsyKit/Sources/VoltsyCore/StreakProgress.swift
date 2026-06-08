// Sources/VoltsyCore/StreakProgress.swift
// Persistable snapshot of the care-streak ledger: streak counts, Power Nap token balance,
// and bookkeeping for weekly token refills + per-day finalization.
import Foundation

public struct StreakProgress: Sendable, Equatable {
    public var currentStreak: Int
    public var longestStreak: Int
    public var tokens: Int
    public var lastRefillWeek: Int          // yearForWeekOfYear*100 + weekOfYear; 0 = never refilled
    public var lastFinalizedDay: Date?
    public var lastDayFrozen: Bool

    public init(currentStreak: Int, longestStreak: Int, tokens: Int,
                lastRefillWeek: Int, lastFinalizedDay: Date?, lastDayFrozen: Bool) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.tokens = tokens
        self.lastRefillWeek = lastRefillWeek
        self.lastFinalizedDay = lastFinalizedDay
        self.lastDayFrozen = lastDayFrozen
    }
}
