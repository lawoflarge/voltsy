// Sources/BatteryEngines/StreakLedger.swift
// Pure finalizer: folds completed days (oldest first, strictly before today) into a
// persisted StreakProgress with a real Power Nap token saldo + weekly refill (spec §192–193).
import Foundation
import VoltsyCore

public enum StreakLedgerEngine {
    /// Fold completed days (oldest first, strictly before today, with data) into the ledger.
    /// `capacity` is the free-tier token cap (1); a new ISO week refills tokens up to it.
    public static func advance(_ start: StreakProgress,
                               completedDays: [(day: Date, healthy: Bool)],
                               capacity: Int, calendar: Calendar) -> StreakProgress {
        var p = start
        for entry in completedDays {
            let wk = calendar.component(.weekOfYear, from: entry.day)
            let yr = calendar.component(.yearForWeekOfYear, from: entry.day)
            let key = yr * 100 + wk
            if key != p.lastRefillWeek {            // new ISO week -> refill to capacity
                p.tokens = max(p.tokens, capacity)
                p.lastRefillWeek = key
            }
            if entry.healthy {
                p.currentStreak += 1
                p.lastDayFrozen = false
            } else if p.tokens > 0 {
                p.tokens -= 1
                p.lastDayFrozen = true             // streak preserved by a Power Nap token
            } else {
                p.currentStreak = 0
                p.lastDayFrozen = false
            }
            p.longestStreak = max(p.longestStreak, p.currentStreak)
            p.lastFinalizedDay = entry.day
        }
        return p
    }
}
