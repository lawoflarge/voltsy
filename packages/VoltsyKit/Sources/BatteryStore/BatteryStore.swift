// Sources/BatteryStore/BatteryStore.swift
import Foundation
import SwiftData
import VoltsyCore

@MainActor
public final class BatteryStore {
    public static let appGroupID = "group.com.lawoflarge.voltsy"
    private let container: ModelContainer

    public init(container: ModelContainer) {
        self.container = container
    }

    /// App-Group-backed store shared by the app, widget, and Live Activity.
    public static func shared() throws -> BatteryStore {
        let config = ModelConfiguration(groupContainer: .identifier(appGroupID))
        let container = try ModelContainer(for: BatterySampleRecord.self, StreakProgressRecord.self, configurations: config)
        return BatteryStore(container: container)
    }

    /// Persistent on-device store in the app sandbox. Used until the App Group is
    /// provisioned; the Widget/Live Activity will switch back to `shared()`.
    public static func local() throws -> BatteryStore {
        let dir = URL.applicationSupportDirectory
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let config = ModelConfiguration(url: dir.appending(path: "Voltsy.store"))
        let container = try ModelContainer(for: BatterySampleRecord.self, StreakProgressRecord.self, configurations: config)
        return BatteryStore(container: container)
    }

    /// In-memory store so a missing App Group entitlement never crashes launch.
    public static func inMemoryFallback() -> BatteryStore {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            let container = try ModelContainer(for: BatterySampleRecord.self, StreakProgressRecord.self, configurations: config)
            return BatteryStore(container: container)
        } catch {
            // An in-memory container has no store to open; init cannot fail in practice.
            preconditionFailure("In-memory ModelContainer init failed (SwiftData regression): \(error)")
        }
    }

    public func append(_ sample: BatterySample) throws {
        let ctx = container.mainContext
        ctx.insert(BatterySampleRecord(sample))
        try ctx.save()
    }

    public func recentSamples(limit: Int) throws -> [BatterySample] {
        var descriptor = FetchDescriptor<BatterySampleRecord>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)])
        descriptor.fetchLimit = limit
        return try container.mainContext.fetch(descriptor).map { $0.toSample() }
    }

    public func samples(since date: Date) throws -> [BatterySample] {
        let descriptor = FetchDescriptor<BatterySampleRecord>(
            predicate: #Predicate { $0.timestamp >= date },
            sortBy: [SortDescriptor(\.timestamp, order: .forward)])
        return try container.mainContext.fetch(descriptor).map { $0.toSample() }
    }

    // MARK: - Streak ledger (persisted singleton)

    public func loadStreakProgress() -> StreakProgress {
        let rec = (try? container.mainContext.fetch(FetchDescriptor<StreakProgressRecord>()))?.first
        guard let r = rec else {
            return StreakProgress(currentStreak: 0, longestStreak: 0, tokens: 1,
                                  lastRefillWeek: 0, lastFinalizedDay: nil, lastDayFrozen: false)
        }
        return StreakProgress(currentStreak: r.currentStreak, longestStreak: r.longestStreak,
                              tokens: r.tokens, lastRefillWeek: r.lastRefillWeek,
                              lastFinalizedDay: r.lastFinalizedDay, lastDayFrozen: r.lastDayFrozen)
    }

    public func saveStreakProgress(_ p: StreakProgress) throws {
        let ctx = container.mainContext
        let existing = (try? ctx.fetch(FetchDescriptor<StreakProgressRecord>()))?.first
        let rec: StreakProgressRecord
        if let existing { rec = existing } else { rec = StreakProgressRecord(); ctx.insert(rec) }
        rec.currentStreak = p.currentStreak
        rec.longestStreak = p.longestStreak
        rec.tokens = p.tokens
        rec.lastRefillWeek = p.lastRefillWeek
        rec.lastFinalizedDay = p.lastFinalizedDay
        rec.lastDayFrozen = p.lastDayFrozen
        try ctx.save()
    }
}

@Model
final class StreakProgressRecord {
    var currentStreak: Int
    var longestStreak: Int
    var tokens: Int
    var lastRefillWeek: Int
    var lastFinalizedDay: Date?
    var lastDayFrozen: Bool
    init(currentStreak: Int = 0, longestStreak: Int = 0, tokens: Int = 1,
         lastRefillWeek: Int = 0, lastFinalizedDay: Date? = nil, lastDayFrozen: Bool = false) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.tokens = tokens
        self.lastRefillWeek = lastRefillWeek
        self.lastFinalizedDay = lastFinalizedDay
        self.lastDayFrozen = lastDayFrozen
    }
}
