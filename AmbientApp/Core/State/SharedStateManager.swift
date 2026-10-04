//
//  SharedStateManager.swift
//  AmbientApp
//

import Foundation

/// Thread-safe manager for reading and writing shared app state between
/// the main app and background extensions using App Group UserDefaults.
public final class SharedStateManager: @unchecked Sendable {

    // MARK: - Singleton

    public static let shared = SharedStateManager()

    // MARK: - Constants

    public static let appGroupName = "group.com.yourdomain.ambientbattery"

    private enum Keys {
        static let isOverloaded = "isOverloaded"
        static let lastUpdated = "lastUpdated"
    }

    /// State validity duration threshold: 4 hours (in seconds).
    public let stateExpirationInterval: TimeInterval = 4 * 3600

    // MARK: - Properties

    private let userDefaults: UserDefaults?
    private let lock = NSLock()

    // MARK: - Initialization

    public init(suiteName: String = SharedStateManager.appGroupName) {
        self.userDefaults = UserDefaults(suiteName: suiteName)
    }

    // MARK: - Public API

    /// Updates the `isOverloaded` state and updates the `lastUpdated` timestamp to the current date.
    /// - Parameter overloaded: Boolean state indicating social battery overload.
    public func setOverloaded(_ overloaded: Bool) {
        lock.lock()
        defer { lock.unlock() }

        guard let userDefaults = userDefaults else { return }
        userDefaults.set(overloaded, forKey: Keys.isOverloaded)
        userDefaults.set(Date(), forKey: Keys.lastUpdated)
    }

    /// Timestamp when the state was last updated.
    public var lastUpdated: Date? {
        lock.lock()
        defer { lock.unlock() }

        return userDefaults?.object(forKey: Keys.lastUpdated) as? Date
    }

    /// Evaluates if the current stored state was updated within the last 4 hours.
    public var isStateValid: Bool {
        lock.lock()
        defer { lock.unlock() }

        guard let timestamp = userDefaults?.object(forKey: Keys.lastUpdated) as? Date else {
            return false
        }
        return Date().timeIntervalSince(timestamp) < stateExpirationInterval
    }

    /// The active `isOverloaded` value. Returns `false` if state is missing or has expired (> 4 hours).
    public var isOverloaded: Bool {
        guard isStateValid else { return false }

        lock.lock()
        defer { lock.unlock() }
        return userDefaults?.bool(forKey: Keys.isOverloaded) ?? false
    }

    /// Returns the raw stored value without checking expiration.
    public var rawIsOverloaded: Bool {
        lock.lock()
        defer { lock.unlock() }

        return userDefaults?.bool(forKey: Keys.isOverloaded) ?? false
    }

    /// Resets all stored keys.
    public func clearState() {
        lock.lock()
        defer { lock.unlock() }

        guard let userDefaults = userDefaults else { return }
        userDefaults.removeObject(forKey: Keys.isOverloaded)
        userDefaults.removeObject(forKey: Keys.lastUpdated)
    }
}
