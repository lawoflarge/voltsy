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
        let container = try ModelContainer(for: BatterySampleRecord.self, configurations: config)
        return BatteryStore(container: container)
    }

    /// In-memory store so a missing App Group entitlement never crashes launch.
    public static func inMemoryFallback() -> BatteryStore {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        do {
            let container = try ModelContainer(for: BatterySampleRecord.self, configurations: config)
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
}
