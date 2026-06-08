import Testing
import Foundation
import SwiftData
import VoltsyCore
@testable import BatteryStore

@MainActor
@Suite("StreakProgressStore")
struct StreakProgressStoreTests {
    private func memStore() throws -> BatteryStore {
        let cfg = ModelConfiguration(isStoredInMemoryOnly: true)
        let c = try ModelContainer(for: BatterySampleRecord.self, StreakProgressRecord.self,
                                   configurations: cfg)
        return BatteryStore(container: c)
    }

    @Test func defaultsThenRoundTrips() throws {
        let s = try memStore()
        #expect(s.loadStreakProgress().currentStreak == 0)   // sensible default
        var p = s.loadStreakProgress()
        p.currentStreak = 5; p.tokens = 0; p.lastRefillWeek = 42
        try s.saveStreakProgress(p)
        #expect(s.loadStreakProgress().currentStreak == 5)
        #expect(s.loadStreakProgress().tokens == 0)
        #expect(s.loadStreakProgress().lastRefillWeek == 42)
    }
}
