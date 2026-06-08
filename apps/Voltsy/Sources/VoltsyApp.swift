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
        WindowGroup { HomeView(model: model) }
    }
}
