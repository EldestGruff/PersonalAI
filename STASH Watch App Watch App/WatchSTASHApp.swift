//
//  WatchSTASHApp.swift
//  STASH Watch App
//
//  Issue #58: Apple Watch companion app
//
//  Entry point for the watchOS app. Activates WatchConnectivity
//  immediately so the queue starts flushing as soon as the app launches.
//

import SwiftUI
import UserNotifications

@main
struct WatchSTASHApp: App {
    init() {
        WatchConnectivityManager.shared.activate()
        UNUserNotificationCenter.current().delegate = WatchNotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            WatchCaptureView()
        }
    }
}
