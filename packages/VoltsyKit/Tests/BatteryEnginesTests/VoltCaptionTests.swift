// Tests/BatteryEnginesTests/VoltCaptionTests.swift
import Testing
import VoltsyCore
@testable import BatteryEngines

@Suite("VoltCaption")
struct VoltCaptionTests {
    @Test("every mood has a non-empty caption")
    func allMoods() {
        for mood in VoltMood.allCases {
            #expect(!VoltCaption.text(for: mood).isEmpty)
        }
    }

    @Test("distinctive states read true to character")
    func specific() {
        #expect(VoltCaption.text(for: .overheating).localizedCaseInsensitiveContains("warm"))
        #expect(VoltCaption.text(for: .critical).localizedCaseInsensitiveContains("charger"))
    }
}
