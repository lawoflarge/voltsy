public enum ThermalLevel: Int, Codable, Sendable, Equatable, Comparable, CaseIterable {
    case nominal = 0, fair = 1, serious = 2, critical = 3
    public static func < (lhs: ThermalLevel, rhs: ThermalLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
