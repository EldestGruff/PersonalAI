//
//  ContentView.swift
//  STASH
//
//  Phase 3A Spec 3: Content View (Legacy)
//  This file is kept for backwards compatibility.
//  The main app now uses MainTabView from PersonalAIApp.swift
//

import SwiftUI
import CoreData

/// Legacy content view - redirects to MainTabView
struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        MainTabView()
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
