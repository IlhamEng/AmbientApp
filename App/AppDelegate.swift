//
//  AppDelegate.swift
//  AmbientApp
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif
import HealthKit

#if canImport(UIKit)
/// App delegate handling background HealthKit observer query wakes.
public final class AppDelegate: NSObject, UIApplicationDelegate, @unchecked Sendable {

    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Register HKObserverQuery background delivery on app launch
        registerHealthKitBackgroundObserver()
        return true
    }

    private func registerHealthKitBackgroundObserver() {
        HealthKitManager.shared.registerBackgroundDelivery { query, completionHandler, error in
            guard error == nil else {
                completionHandler()
                return
            }

            // Execute fast background pipeline (< 2s constraint: read -> infer -> store)
            Task {
                defer { completionHandler() }

                do {
                    let hrvValue = try await HealthKitManager.shared.fetchLatestHRVSample()
                    let stepCount = try await HealthKitManager.shared.fetchStepCount(
                        since: Calendar.current.startOfDay(for: Date())
                    )

                    let isOverloaded = try await BatteryClassifier.shared.evaluateAndSaveState(
                        hrv: hrvValue,
                        stepCount: stepCount
                    )

                    print("[AppDelegate] Background pipeline evaluated isOverloaded: \(isOverloaded)")
                } catch {
                    print("[AppDelegate] Error running background evaluation: \(error.localizedDescription)")
                }
            }
        }
    }
}
#endif
