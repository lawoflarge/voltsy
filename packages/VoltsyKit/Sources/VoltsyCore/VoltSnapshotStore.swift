// Sources/VoltsyCore/VoltSnapshotStore.swift
// Tiny App-Group bridge: the app writes the latest Volt state; the widget reads it.
// Avoids sharing the full SwiftData store with the widget — the widget only needs the look.
import Foundation

public enum VoltSnapshotStore {
    public static let appGroupID = "group.com.lawoflarge.voltsy"
    private static let key = "voltSnapshot"

    public static func write(_ state: VoltState) {
        guard let d = UserDefaults(suiteName: appGroupID),
              let data = try? JSONEncoder().encode(state) else { return }
        d.set(data, forKey: key)
    }

    public static func read() -> VoltState? {
        guard let d = UserDefaults(suiteName: appGroupID),
              let data = d.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(VoltState.self, from: data)
    }
}
