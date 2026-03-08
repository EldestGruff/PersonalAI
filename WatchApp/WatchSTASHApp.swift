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

@main
struct WatchSTASHApp: App {
    init() {
        WatchConnectivityManager.shared.activate()
    }

    var body: some Scene {
        WindowGroup {
            WatchCaptureView()
        }
    }
}
