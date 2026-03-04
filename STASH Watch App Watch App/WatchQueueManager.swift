//
//  WatchQueueManager.swift
//  STASH Watch App
//
//  Issue #58: Apple Watch companion app
//
//  Actor-based offline queue for voice captures.
//  Persists to UserDefaults so thoughts survive app backgrounding and relaunch.
//  WatchConnectivityManager drains the queue when the session is active.
//

import Foundation

// MARK: - Queued Thought

struct WatchQueuedThought: Codable, Identifiable, Sendable {
    let id: UUID
    let text: String
    let capturedAt: Date
}

// MARK: - Watch Queue Manager

actor WatchQueueManager {
    static let shared = WatchQueueManager()

    private let defaults = UserDefaults.standard
    private let key = "watchCaptureQueue"

    // MARK: - Queue Operations

    /// Appends a new thought and persists the queue. Returns the queued item.
    @discardableResult
    func enqueue(_ text: String) -> WatchQueuedThought {
        let item = WatchQueuedThought(id: UUID(), text: text, capturedAt: Date())
        var queue = load()
        queue.append(item)
        save(queue)
        return item
    }

    /// All pending thoughts (not yet confirmed delivered to iPhone).
    func all() -> [WatchQueuedThought] {
        load()
    }

    /// Removes a single item by ID (called after successful WCSession transfer).
    func remove(_ id: UUID) {
        var queue = load()
        queue.removeAll { $0.id == id }
        save(queue)
    }

    // MARK: - Persistence

    private func load() -> [WatchQueuedThought] {
        guard
            let data = defaults.data(forKey: key),
            let queue = try? JSONDecoder().decode([WatchQueuedThought].self, from: data)
        else { return [] }
        return queue
    }

    private func save(_ queue: [WatchQueuedThought]) {
        guard let data = try? JSONEncoder().encode(queue) else { return }
        defaults.set(data, forKey: key)
    }
}
