// apps/Voltsy/Sources/VoltsyApp.swift
import SwiftUI
import BatteryStore

@main
struct VoltsyApp: App {
    @State private var model: HomeViewModel = {
        let store = (try? BatteryStore.shared()) ?? BatteryStore.inMemoryFallback()
        return HomeViewModel(store: store)
    }()

    var body: some Scene {
        // TEMP (feat/volt-mascot): show the mood gallery to iterate on Volt's look.
        // Reverts to HomeView once the mascot design is locked.
        WindowGroup { VoltGalleryView() }
    }
}
