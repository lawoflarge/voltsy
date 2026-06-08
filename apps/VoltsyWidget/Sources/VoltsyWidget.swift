// apps/VoltsyWidget/Sources/VoltsyWidget.swift
import WidgetKit
import SwiftUI
import VoltsyCore
import VoltMascot

struct VoltEntry: TimelineEntry {
    let date: Date
    let state: VoltState
}

struct VoltProvider: TimelineProvider {
    private var fallback: VoltState { VoltState(mood: .content, bellyFill: 0.6, tint: .green) }
    func placeholder(in context: Context) -> VoltEntry { VoltEntry(date: Date(), state: fallback) }
    func getSnapshot(in context: Context, completion: @escaping (VoltEntry) -> Void) {
        completion(VoltEntry(date: Date(), state: VoltSnapshotStore.read() ?? fallback))
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<VoltEntry>) -> Void) {
        let entry = VoltEntry(date: Date(), state: VoltSnapshotStore.read() ?? fallback)
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct VoltsyWidgetEntryView: View {
    var entry: VoltEntry
    var body: some View {
        VoltView(state: entry.state, size: 96)
            .containerBackground(.background, for: .widget)
    }
}

struct VoltsyWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "VoltsyWidget", provider: VoltProvider()) { entry in
            VoltsyWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Volt")
        .description("Your battery buddy at a glance.")
        .supportedFamilies([.systemSmall])
    }
}

@main
struct VoltsyWidgetBundle: WidgetBundle {
    var body: some Widget { VoltsyWidget() }
}
