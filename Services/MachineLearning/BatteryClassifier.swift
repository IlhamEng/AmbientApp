//
//  BatteryClassifier.swift
//  AmbientApp
//

import Foundation
import CoreML

/// Protocol defining the interface for social battery classification engines.
public protocol ClassifierEngine: Sendable {
    /// Evaluates input physiological and activity metrics to classify social battery overload.
    /// - Parameters:
    ///   - hrv: Heart rate variability (SDNN in milliseconds).
    ///   - stepCount: Cumulative step count for recent window.
    /// - Returns: `true` if the user is classified as overloaded; otherwise `false`.
    func classify(hrv: Double?, stepCount: Double?) async throws -> Bool
}

/// Mock classifier implementation using configurable threshold rules and random variance
/// for testing pipeline integration prior to CoreML `.mlmodel` injection.
public final class MockBatteryClassifier: ClassifierEngine, @unchecked Sendable {

    /// Default HRV threshold (ms) below which stress/overload is indicated.
    public let hrvThreshold: Double
    /// Default Step Count threshold above which fatigue is factored.
    public let stepThreshold: Double

    public init(hrvThreshold: Double = 40.0, stepThreshold: Double = 7500.0) {
        self.hrvThreshold = hrvThreshold
        self.stepThreshold = stepThreshold
    }

    public func classify(hrv: Double?, stepCount: Double?) async throws -> Bool {
        // Fast evaluation ensuring execution under 2 seconds requirement
        let currentHRV = hrv ?? Double.random(in: 20.0...80.0)
        let currentSteps = stepCount ?? Double.random(in: 1000.0...12000.0)

        let isLowHRV = currentHRV < hrvThreshold
        let isHighSteps = currentSteps > stepThreshold

        // Overloaded if HRV is abnormally low, or both moderate HRV and high step count exist
        let calculatedOverloaded = isLowHRV || (currentHRV < (hrvThreshold + 15.0) && isHighSteps)

        return calculatedOverloaded
    }
}

/// CoreML wrapper service managing classification execution and updating shared app state.
public final class BatteryClassifier: @unchecked Sendable {

    public static let shared = BatteryClassifier()

    private let engine: ClassifierEngine

    public init(engine: ClassifierEngine = MockBatteryClassifier()) {
        self.engine = engine
    }

    /// Evaluates current metrics and updates `SharedStateManager`.
    /// - Parameters:
    ///   - hrv: Latest HRV SDNN sample in milliseconds.
    ///   - stepCount: Latest cumulative step count.
    /// - Returns: The boolean overloaded state result.
    @discardableResult
    public func evaluateAndSaveState(hrv: Double?, stepCount: Double?) async throws -> Bool {
        let isOverloaded = try await engine.classify(hrv: hrv, stepCount: stepCount)

        // Write computed state to SharedStateManager (Privacy compliance: raw values are not cached)
        SharedStateManager.shared.setOverloaded(isOverloaded)

        return isOverloaded
    }
}
