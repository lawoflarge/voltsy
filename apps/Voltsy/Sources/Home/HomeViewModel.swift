// apps/Voltsy/Sources/Home/HomeViewModel.swift
import Foundation
import VoltsyCore
import BatteryEngines
import BatteryStore

@MainActor
@Observable
final class HomeViewModel {
    private let store: BatteryStore
    private(set) var monitor: BatteryMonitor!
    private(set) var voltState: VoltState =
        VoltState(mood: .content, bellyFill: 0.5, tint: .green)
    private(set) var careScore: CareScore =
        CareScore(value: nil, confidence: .insufficient(accruedCycles: 0, needed: 3), tint: .green)

    init(store: BatteryStore) {
        self.store = store
        self.monitor = BatteryMonitor { [weak self] sample in
            self?.ingest(sample)
        }
    }

    func tick() { monitor.refresh() }

    private func ingest(_ sample: BatterySample) {
        try? store.append(sample)
        let recent = (try? store.samples(since: Date().addingTimeInterval(-60 * 60 * 24 * 30))) ?? [sample]
        let score = CareScoreEngine.score(from: recent)
        let minutesFull = SessionEngine.minutesAtFull(from: recent)
        voltState = VoltStateMapper.map(level: sample.level, state: sample.state,
                                        thermal: sample.thermal, lowPowerMode: sample.lowPowerMode,
                                        minutesAtFull: minutesFull, tint: score.tint)
        careScore = score
    }
}
