// Sources/BatteryEngines/ReviewPromptGate.swift
// Decide whether to request an App Store review NOW — only on a positive streak milestone,
// once per milestone (spec F6). The system separately caps to ~3 prompts/year. Pure.
public enum ReviewPromptGate {
    public static let milestones = [3, 7, 30]

    /// True when `streak` exactly hits a milestone we haven't asked at yet.
    public static func shouldRequest(streak: Int, lastAskedMilestone: Int?) -> Bool {
        guard milestones.contains(streak) else { return false }
        return streak > (lastAskedMilestone ?? 0)
    }
}
