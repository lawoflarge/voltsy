// Sources/BatteryEngines/CareScoreEngine.swift
import Foundation
import VoltsyCore

public enum CareScoreEngine {
    public static let minCyclesForScore: Double = 1.5
    public static let heatPenaltyPerMinute = 0.05      // minutes at thermal >= serious
    public static let deepDischargePenalty = 4.0       // per discharge session ending <= 5%
    public static let overchargeGraceMinutes = 60.0
    public static let overchargePenaltyPerMinute = 0.02

    public static func appAccruedCycles(from sessions: [BatterySession]) -> Double {
        sessions.filter { $0.kind == .discharge }
                .reduce(0) { $0 + max(0, -$1.levelDelta) }
    }

    public static func score(from samples: [BatterySample]) -> CareScore {
        let sorted = samples.sorted { $0.timestamp < $1.timestamp }
        let sessions = SessionEngine.sessions(from: sorted)
        let accrued = appAccruedCycles(from: sessions)

        guard accrued >= minCyclesForScore else {
            return CareScore(value: nil,
                             confidence: .insufficient(accruedCycles: accrued, needed: minCyclesForScore),
                             tint: .green)
        }

        // Heat exposure: minutes where thermal >= serious, attributed to the interval before each sample.
        var hotMinutes = 0.0
        for i in 1..<sorted.count {
            if sorted[i].thermal >= .serious {
                hotMinutes += sorted[i].timestamp.timeIntervalSince(sorted[i - 1].timestamp) / 60
            }
        }

        let deepDischarges = sessions.filter { $0.kind == .discharge && $0.endLevel <= 0.05 }.count
        let overchargeMinutes = max(0, Double(SessionEngine.minutesAtFull(from: sorted)) - overchargeGraceMinutes)

        var value = 100.0
        value -= hotMinutes * heatPenaltyPerMinute
        value -= Double(deepDischarges) * deepDischargePenalty
        value -= overchargeMinutes * overchargePenaltyPerMinute
        let clamped = Int(min(100, max(0, value)).rounded())

        let tint: HealthTint = clamped >= 80 ? .green : (clamped >= 50 ? .amber : .red)
        return CareScore(value: clamped, confidence: .estimating(accruedCycles: accrued), tint: tint)
    }
}
