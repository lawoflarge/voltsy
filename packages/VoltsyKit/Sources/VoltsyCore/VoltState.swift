public enum VoltMood: String, Codable, Sendable, Equatable, CaseIterable {
    case energetic        // 80–100%, healthy
    case content          // 40–80%, the sweet spot
    case tired            // 15–30%
    case critical         // 1–10%
    case charging         // plugged in and rising
    case overcharged      // sustained 100%
    case overheating      // high thermal state
    case zen              // Low Power Mode
}

public struct VoltState: Sendable, Equatable, Codable, Hashable {
    public let mood: VoltMood
    public let bellyFill: Double        // 0...1 — what the mascot renders
    public let tint: HealthTint

    public init(mood: VoltMood, bellyFill: Double, tint: HealthTint) {
        self.mood = mood
        self.bellyFill = bellyFill
        self.tint = tint
    }
}
