// apps/Voltsy/Sources/VoltsyApp.swift
import SwiftUI
import BatteryStore
import Monetization

@main
struct VoltsyApp: App {
    @State private var model: HomeViewModel = {
        // App Group is deferred until the Widget/Live Activity ships. Calling shared()
        // without the entitlement is a hard SwiftData fatalError (NOT a catchable throw),
        // so `try?` can't save us — use the on-device store directly for now.
        let store = (try? BatteryStore.local()) ?? BatteryStore.inMemoryFallback()
        return HomeViewModel(store: store)
    }()
    @State private var proStore = ProStore()

    var body: some Scene {
        WindowGroup { HomeView(model: model).environment(proStore) }
    }
}
