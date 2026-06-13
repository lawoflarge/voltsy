// apps/Voltsy/Sources/Notifications/VoltNotifications.swift
// Thin scheduler: permission + a daily evening streak-protection nudge. Volt-voiced copy.
// The richer state nudges (VoltNotificationEngine) feed the Live Activity / foreground later.
import Foundation
import UserNotifications
import BatteryEngines

@MainActor
final class VoltNotifications {
    private let center = UNUserNotificationCenter.current()
    private let streakID = "voltsy.streak.evening"

    /// Suspends until the user responds so the caller can sequence launch prompts.
    func requestPermissionIfNeeded() async {
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
    }

    /// Daily 20:00 nudge to protect an active streak; cancelled when there is no streak.
    func scheduleEveningStreakReminder(streak: Int) {
        center.removePendingNotificationRequests(withIdentifiers: [streakID])
        guard streak > 0 else { return }
        let content = UNMutableNotificationContent()
        content.body = "Don't let our \(streak)-day streak fizzle — spend a moment with Volt today! 🔥"
        content.sound = .default
        var comps = DateComponents()
        comps.hour = 20
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: streakID, content: content, trigger: trigger)
        Task { try? await center.add(request) }
    }

    /// Post a one-shot local notification now (best-effort; delivered when iOS lets the app
    /// run — see the Trust screen's honesty note). De-dup is the caller's job.
    func fireImmediate(_ message: VoltMessage) {
        let content = UNMutableNotificationContent()
        content.body = message.body
        content.sound = .default
        let request = UNNotificationRequest(identifier: "voltsy.alert.\(message.kind.rawValue)",
                                            content: content, trigger: nil)
        Task { try? await center.add(request) }
    }
}
