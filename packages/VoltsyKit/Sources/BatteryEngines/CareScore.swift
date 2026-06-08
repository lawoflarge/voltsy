// Sources/BatteryEngines/CareScore.swift
import VoltsyCore

public struct CareScore: Sendable, Equatable {
    public enum Confidence: Sendable, Equatable {
        case insufficient(accruedCycles: Double, needed: Double)
        case estimating(accruedCycles: Double)
    }
    public let value: Int?            // nil until enough data — UI must not invent a number
    public let confidence: Confidence
    public let tint: HealthTint

    public init(value: Int?, confidence: Confidence, tint: HealthTint) {
        self.value = value
        self.confidence = confidence
        self.tint = tint
    }
}
