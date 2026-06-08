// Tests/BatteryStoreTests/BatteryStoreTests.swift
import Testing
import Foundation
import SwiftData
import VoltsyCore
@testable import BatteryStore

@MainActor
@Suite("BatteryStore")
struct BatteryStoreTests {
    private func inMemoryStore() throws -> BatteryStore {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: BatterySampleRecord.self, configurations: config)
        return BatteryStore(container: container)
    }

    @Test("append then fetch round-trips a sample")
    func roundTrip() throws {
        let store = try inMemoryStore()
        let sample = BatterySample(timestamp: Date(timeIntervalSince1970: 100), level: 0.42,
                                   state: .unplugged, lowPowerMode: true, thermal: .fair)
        try store.append(sample)
        let all = try store.recentSamples(limit: 10)
        #expect(all.count == 1)
        #expect(all[0] == sample)
    }

    @Test("recentSamples returns newest first and respects the limit")
    func ordering() throws {
        let store = try inMemoryStore()
        for i in 0..<5 {
            try store.append(BatterySample(timestamp: Date(timeIntervalSince1970: Double(i)),
                                           level: 0.5, state: .unplugged, lowPowerMode: false, thermal: .nominal))
        }
        let recent = try store.recentSamples(limit: 2)
        #expect(recent.count == 2)
        #expect(recent[0].timestamp > recent[1].timestamp)
    }
}
