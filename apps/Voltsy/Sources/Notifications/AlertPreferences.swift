// apps/Voltsy/Sources/Notifications/AlertPreferences.swift
// Persisted alert thresholds. Free is fixed at the defaults; Pro may change them (spec P1).
// Stored as whole percent for clean UI; ChargeAlertEngine consumes 0...1 fractions.
import Foundation

@MainActor
@Observable
final class AlertPreferences {
    static let defaultHighPercent = 80
    static let defaultLowPercent = 15

    private let highKey = "voltsy.alert.highPercent"
    private let lowKey = "voltsy.alert.lowPercent"

    var highPercent: Int {
        didSet { UserDefaults.standard.set(highPercent, forKey: highKey) }
    }
    var lowPercent: Int {
        didSet { UserDefaults.standard.set(lowPercent, forKey: lowKey) }
    }

    init() {
        let d = UserDefaults.standard
        highPercent = d.object(forKey: highKey) as? Int ?? Self.defaultHighPercent
        lowPercent = d.object(forKey: lowKey) as? Int ?? Self.defaultLowPercent
    }

    /// Thresholds applied for a given tier: Pro uses the stored values; Free is forced to the
    /// defaults regardless of any previously-stored Pro values (so a lapsed Pro can't keep them).
    func effective(isPro: Bool) -> (high: Double, low: Double) {
        if isPro { return (Double(highPercent) / 100, Double(lowPercent) / 100) }
        return (Double(Self.defaultHighPercent) / 100, Double(Self.defaultLowPercent) / 100)
    }
}
