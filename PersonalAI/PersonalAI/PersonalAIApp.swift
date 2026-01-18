//
//  PersonalAIApp.swift
//  PersonalAI
//
//  Created by Andy Fenner on 1/15/26.
//

import SwiftUI
import CoreData

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
