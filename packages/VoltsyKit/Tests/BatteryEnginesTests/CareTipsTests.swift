// Tests/BatteryEnginesTests/CareTipsTests.swift
import Testing
import VoltsyCore
@testable import BatteryEngines

@Suite("CareTips")
struct CareTipsTests {
    @Test("there is a non-trivial, unique-id tip list")
    func list() {
        #expect(CareTips.all.count >= 5)
        #expect(Set(CareTips.all.map(\.id)).count == CareTips.all.count)
        #expect(CareTips.all.allSatisfy { !$0.title.isEmpty && !$0.body.isEmpty && !$0.icon.isEmpty })
    }

    @Test("overheating surfaces the heat tip")
    func heatContext() {
        let tip = CareTips.contextual(thermal: .serious, lowPowerMode: false, level: 0.5)
        #expect(tip.id == "heat")
    }

    @Test("a calm nominal state still returns a real tip")
    func nominalContext() {
        let tip = CareTips.contextual(thermal: .nominal, lowPowerMode: false, level: 0.5)
        #expect(!tip.title.isEmpty)
    }
}
