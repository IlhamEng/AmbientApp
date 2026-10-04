//
//  HealthKitManager.swift
//  AmbientApp
//

import Foundation
import HealthKit

/// Service managing HealthKit authorization, background observer queries,
/// and fast retrieval of HRV and step count metrics.
public final class HealthKitManager: @unchecked Sendable {

    // MARK: - Singleton

    public static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()

    private init() {}

    // MARK: - Quantity Types

    public var hrvType: HKQuantityType? {
        HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)
    }

    public var stepCountType: HKQuantityType? {
        HKQuantityType.quantityType(forIdentifier: .stepCount)
    }

    // MARK: - Authorization

    /// Requests `.read` authorization for HRV and Step Count.
    public func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.healthDataUnavailable
        }

        var readTypes = Set<HKObjectType>()
        if let hrvType = hrvType { readTypes.insert(hrvType) }
        if let stepCountType = stepCountType { readTypes.insert(stepCountType) }

        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
    }

    // MARK: - Background Observer Delivery

    /// Registers an `HKObserverQuery` and enables background delivery for HRV.
    /// - Parameter updateHandler: Callback executed when background updates are delivered.
    ///   Must call `completionHandler()` quickly (< 2 seconds).
    public func registerBackgroundDelivery(
        updateHandler: @escaping @Sendable (HKObserverQuery, @escaping HKObserverQueryCompletionHandler, Error?) -> Void
    ) {
        guard HKHealthStore.isHealthDataAvailable(), let hrvType = hrvType else { return }

        let observerQuery = HKObserverQuery(sampleType: hrvType, predicate: nil) { query, completionHandler, error in
            updateHandler(query, completionHandler, error)
        }

        healthStore.execute(observerQuery)

        healthStore.enableBackgroundDelivery(for: hrvType, frequency: .immediate) { _, error in
            if let error = error {
                print("[HealthKitManager] Failed background delivery setup: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Sample Fetching

    /// Fetches the single most recent HRV (SDNN) sample value in milliseconds.
    public func fetchLatestHRVSample() async throws -> Double? {
        guard let hrvType = hrvType else { return nil }

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: hrvType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, results, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let sample = results?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }

                let hrvInMs = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                continuation.resume(returning: hrvInMs)
            }

            healthStore.execute(query)
        }
    }

    /// Fetches cumulative step count since the provided start date.
    public func fetchStepCount(since startDate: Date) async throws -> Double {
        guard let stepCountType = stepCountType else { return 0 }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepCountType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                let sum = statistics?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                continuation.resume(returning: sum)
            }

            healthStore.execute(query)
        }
    }
}

public enum HealthKitError: Error, LocalizedError {
    case healthDataUnavailable

    public var errorDescription: String? {
        switch self {
        case .healthDataUnavailable:
            return "HealthKit is not available on this device."
        }
    }
}
