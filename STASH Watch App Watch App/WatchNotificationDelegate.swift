//
//  WatchNotificationDelegate.swift
//  STASH Watch App
//
//  Displays notification banners even when the app is in the foreground.
//  Wired into WatchSTASHApp.init().
//

import UserNotifications

final class WatchNotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = WatchNotificationDelegate()
    private override init() {}

    /// Show banner + play sound even when the Watch app is active.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
