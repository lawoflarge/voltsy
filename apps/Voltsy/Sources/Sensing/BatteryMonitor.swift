// apps/Voltsy/Sources/Sensing/BatteryMonitor.swift
import Foundation
import UIKit
import VoltsyCore

@MainActor
@Observable
public final class BatteryMonitor {
    public private(set) var current: BatterySample

    private let onSample: @MainActor (BatterySample) -> Void

    public init(onSample: @escaping @MainActor (BatterySample) -> Void) {
        self.onSample = onSample
        UIDevice.current.isBatteryMonitoringEnabled = true
        self.current = BatteryMonitor.snapshot()

        let center = NotificationCenter.default
        for name: NSNotification.Name in [
            UIDevice.batteryLevelDidChangeNotification,
            UIDevice.batteryStateDidChangeNotification,
            .NSProcessInfoPowerStateDidChange,
            ProcessInfo.thermalStateDidChangeNotification
        ] {
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.refresh() }
            }
        }
        onSample(current)
    }

    /// Call from a SwiftUI TimelineView tick to pick up rounding changes the OS didn't post.
    public func refresh() {
        let sample = BatteryMonitor.snapshot()
        guard sample != current else { return }
        current = sample
        onSample(sample)
    }

    private static func snapshot() -> BatterySample {
        let device = UIDevice.current
        let state: BatteryChargeState
        switch device.batteryState {
        case .charging: state = .charging
        case .full: state = .full
        case .unplugged: state = .unplugged
        default: state = .unknown
        }
        let thermal: ThermalLevel
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: thermal = .nominal
        case .fair: thermal = .fair
        case .serious: thermal = .serious
        case .critical: thermal = .critical
        @unknown default: thermal = .nominal
        }
        return BatterySample(
            timestamp: Date(),
            level: Double(device.batteryLevel),   // -1.0 when unknown
            state: state,
            lowPowerMode: ProcessInfo.processInfo.isLowPowerModeEnabled,
            thermal: thermal)
    }
}
