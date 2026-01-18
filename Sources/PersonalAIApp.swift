//
//  PersonalAIApp.swift
//  PersonalAI
//
//  Phase 3A: App entry point
//  Main app structure with Core Data integration
//

import SwiftUI

@main
struct PersonalAIApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
