public enum BatteryChargeState: String, Codable, Sendable, Equatable, CaseIterable {
    case unknown, unplugged, charging, full
}
