//
//  DeviceUser.swift
//  STASH
//
//  Provides a stable, device-local user identifier.
//
//  In Phase 3A there is a single local user. This ID is persisted in UserDefaults
//  on first launch and reused for every thought. It ensures all thoughts share
//  the same userId instead of getting a fresh UUID per capture.
//
//  When multi-user support arrives (Phase 4+), replace the UserDefaults
//  storage with the authenticated session's user ID.
//

import Foundation

/// Device-local user identity.
///
/// Provides a stable `userId` that persists across app launches.
/// The ID is generated once (UUID v4) and stored in `UserDefaults`.
///
/// ## Usage
/// ```swift
/// let thought = Thought(
///     id: UUID(),
///     userId: DeviceUser.id,
///     ...
/// )
/// ```
enum DeviceUser {
    /// Stable device-local user ID.
    ///
    /// Generated once on first access and persisted to `UserDefaults`.
    /// All thoughts created on this device share the same `userId`.
    static var id: UUID {
        let key = AppStorageKeys.Capture.stableUserId
        if let stored = UserDefaults.standard.string(forKey: key),
           let uuid = UUID(uuidString: stored) {
            return uuid
        }
        let fresh = UUID()
        UserDefaults.standard.set(fresh.uuidString, forKey: key)
        return fresh
    }
}
