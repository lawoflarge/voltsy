// apps/VoltsyWidget/Sources/VoltChargingLiveActivity.swift
// The charging Live Activity UI: Lock Screen banner + Dynamic Island. Pure presentation —
// it reads context.state and hands it to the shared ChargingActivity* views.
#if canImport(ActivityKit)
import ActivityKit
import WidgetKit
import SwiftUI

struct VoltChargingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: VoltActivityAttributes.self) { context in
            ChargingLockScreenView(state: context.state)
                .activityBackgroundTint(Color.black.opacity(0.25))
                .activitySystemActionForegroundColor(.primary)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    ChargingExpandedLeading(state: context.state)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    ChargingExpandedTrailing(state: context.state)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ChargingExpandedBottom(state: context.state)
                }
            } compactLeading: {
                Image(systemName: "bolt.fill").foregroundStyle(.yellow)
            } compactTrailing: {
                Text("\(context.state.percent)%").monospacedDigit()
            } minimal: {
                Image(systemName: "bolt.fill").foregroundStyle(.yellow)
            }
        }
    }
}
#endif
