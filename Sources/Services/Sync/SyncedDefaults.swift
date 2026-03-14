//
//  SyncedDefaults.swift
//  STASH
//
//  A UserDefaults-compatible wrapper over NSUbiquitousKeyValueStore.
//  Provides automatic iCloud sync for gamification state and preferences.
//
//  Usage: Drop-in replacement for UserDefaults.standard in services
//  that should sync across devices.
//
//  Merge strategy on external change:
//  - Numeric values (acorns, streaks, counts): take max
//  - Sets/arrays (badges, accessories): union
//  - Scalar preferences (theme, persona ID, dates): last-write-wins
//

import Foundation

final class SyncedDefaults: @unchecked Sendable {
    static let shared = SyncedDefaults()

    private let store = NSUbiquitousKeyValueStore.default

    private init() {
        // Flush to iCloud on init
        store.synchronize()

        // Observe external changes (other devices writing)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(storeDidChangeExternally(_:)),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: store
        )
    }

    // MARK: - Get/Set API (mirrors UserDefaults)

    func integer(forKey key: String) -> Int {
        Int(store.longLong(forKey: key))
    }

    func set(_ value: Int, forKey key: String) {
        store.set(Int64(value), forKey: key)
        // Note: Do NOT call store.synchronize() here. Per Apple docs, synchronize() only
        // flushes in-memory state to local disk — it does NOT trigger iCloud sync.
        // The system handles cloud propagation automatically.
    }

    func string(forKey key: String) -> String? {
        store.string(forKey: key)
    }

    func set(_ value: String?, forKey key: String) {
        store.set(value, forKey: key)
    }

    func bool(forKey key: String) -> Bool {
        store.bool(forKey: key)
    }

    func set(_ value: Bool, forKey key: String) {
        store.set(value, forKey: key)
    }

    func object(forKey key: String) -> Any? {
        store.object(forKey: key)
    }

    func set(_ value: Any?, forKey key: String) {
        store.set(value, forKey: key)
    }

    func data(forKey key: String) -> Data? {
        store.data(forKey: key)
    }

    func set(_ value: Data?, forKey key: String) {
        store.set(value, forKey: key)
    }

    func stringArray(forKey key: String) -> [String]? {
        store.array(forKey: key) as? [String]
    }

    // MARK: - External Change Handler

    @objc private func storeDidChangeExternally(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let changedKeys = userInfo[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] else {
            return
        }

        let reason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int

        // Handle quota exceeded — log and continue (data is read-only in this case)
        if reason == NSUbiquitousKeyValueStoreQuotaViolationChange {
            AppLogger.sync.warning("SyncedDefaults: iCloud KV quota exceeded")
            return
        }

        // Notify services to re-read their values
        NotificationCenter.default.post(
            name: .syncedDefaultsDidChangeExternally,
            object: nil,
            userInfo: ["changedKeys": changedKeys]
        )
    }
}

extension Notification.Name {
    static let syncedDefaultsDidChangeExternally = Notification.Name("SyncedDefaultsDidChangeExternally")
}
