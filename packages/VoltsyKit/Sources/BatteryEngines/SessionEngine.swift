// Sources/BatteryEngines/SessionEngine.swift
import Foundation
import VoltsyCore

public enum SessionEngine {
    public static let gapThreshold: TimeInterval = 30 * 60   // 30 minutes

    private static func kind(for state: BatteryChargeState) -> BatterySession.Kind? {
        switch state {
        case .charging, .full: return .charge
        case .unplugged: return .discharge
        case .unknown: return nil
        }
    }

    public static func sessions(from samples: [BatterySample]) -> [BatterySession] {
        let usable = samples
            .filter { $0.isLevelKnown && kind(for: $0.state) != nil }
            .sorted { $0.timestamp < $1.timestamp }
        guard usable.count >= 2 else { return [] }

        var result: [BatterySession] = []
        var runStartIdx = 0

        func flush(_ startIdx: Int, _ endIdx: Int) {
            guard endIdx > startIdx else { return }
            let first = usable[startIdx], last = usable[endIdx]
            guard let k = kind(for: first.state) else { return }
            result.append(BatterySession(kind: k, start: first.timestamp, end: last.timestamp,
                                         startLevel: first.level, endLevel: last.level))
        }

        for i in 1..<usable.count {
            let prev = usable[i - 1], cur = usable[i]
            let kindChanged = kind(for: prev.state) != kind(for: cur.state)
            let gapped = cur.timestamp.timeIntervalSince(prev.timestamp) > gapThreshold
            if kindChanged || gapped {
                flush(runStartIdx, i - 1)
                runStartIdx = i
            }
        }
        flush(runStartIdx, usable.count - 1)
        return result
    }

    /// Minutes of the most recent contiguous tail where state == .full.
    public static func minutesAtFull(from samples: [BatterySample]) -> Int {
        let sorted = samples.sorted { $0.timestamp < $1.timestamp }
        guard let last = sorted.last, last.state == .full else { return 0 }
        var startOfFull = last.timestamp
        for sample in sorted.reversed() {
            if sample.state == .full { startOfFull = sample.timestamp } else { break }
        }
        return Int(last.timestamp.timeIntervalSince(startOfFull) / 60)
    }
}
