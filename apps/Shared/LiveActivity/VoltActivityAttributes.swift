// apps/Shared/LiveActivity/VoltActivityAttributes.swift
// Shared by the app (starts/updates the Activity) and the widget extension (renders it).
// Added to BOTH targets via project.yml — Apple's canonical pattern for Live Activity
// attribute sharing (matched by type name; ContentState travels as Codable).
#if canImport(ActivityKit)
import ActivityKit
import VoltsyCore

struct VoltActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var voltState: VoltState
        var percent: Int
        var etaMinutes: Int?
        var targetIsFull: Bool   // false → charging toward 80%, true → toward 100%
        var isComplete: Bool     // battery full / target reached
    }
}
#endif
