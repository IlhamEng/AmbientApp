//
//  PermissionManager.swift
//  AmbientApp
//

import Foundation
import SwiftUI
import Observation

/// Coordinates permission requests for HealthKit and User Notifications.
@MainActor
@Observable
public final class PermissionManager {

    public var isHealthKitAuthorized: Bool = false
    public var isNotificationAuthorized: Bool = false

    public init() {}

    /// Requests system permissions sequentially.
    public func requestAllPermissions() async {
        do {
            try await HealthKitManager.shared.requestAuthorization()
            isHealthKitAuthorized = true
        } catch {
            print("[PermissionManager] HealthKit auth failed: \(error.localizedDescription)")
            isHealthKitAuthorized = false
        }

        do {
            let granted = try await NotificationEngine.shared.requestAuthorization()
            isNotificationAuthorized = granted
        } catch {
            print("[PermissionManager] Notification auth failed: \(error.localizedDescription)")
            isNotificationAuthorized = false
        }
    }
}
