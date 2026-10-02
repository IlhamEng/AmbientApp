//
//  NotificationEngine.swift
//  AmbientApp
//

import Foundation
import UserNotifications

/// Engine for registering notification categories and triggering time-sensitive local push notifications.
public final class NotificationEngine: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {

    // MARK: - Singleton

    public static let shared = NotificationEngine()

    // MARK: - Constants

    public static let categoryIdentifier = "RECHARGE_ALERT_CATEGORY"
    public static let actionIdentifier = "ENABLE_RECHARGE_ACTION"

    private override init() {
        super.init()
    }

    // MARK: - Public Methods

    /// Requests authorization for local notifications (.alert, .sound, .badge) and registers categories.
    public func requestAuthorization() async throws -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        registerCategories()
        return granted
    }

    /// Registers custom notification category with "Enable Recharge" action button.
    public func registerCategories() {
        let rechargeAction = UNNotificationAction(
            identifier: Self.actionIdentifier,
            title: "Enable Recharge",
            options: [.foreground]
        )

        let category = UNNotificationCategory(
            identifier: Self.categoryIdentifier,
            actions: [rechargeAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        UNUserNotificationCenter.current().setNotificationCategories([category])
    }

    /// Triggers a `.timeSensitive` local push notification warning of social battery overload.
    public func triggerOverloadNotification(
        title: String = "Social Battery Overloaded",
        body: String = "Your HRV and activity indicators suggest social fatigue. Tap to recharge."
    ) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        content.categoryIdentifier = Self.categoryIdentifier

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "ambient.overload.\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        try await UNUserNotificationCenter.current().add(request)
    }
}
