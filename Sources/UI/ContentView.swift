//
//  ContentView.swift
//  PersonalAI
//
//  Phase 3A: Main content view
//  Placeholder UI - will be implemented in Phase 3A Spec 3
//

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "brain.head.profile")
                    .imageScale(.large)
                    .foregroundStyle(.tint)
                    .font(.system(size: 60))
                    .padding()

                Text("Personal AI")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Phase 3A: Data Models & Persistence")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)

                Spacer()
                    .frame(height: 40)

                VStack(alignment: .leading, spacing: 12) {
                    StatusRow(icon: "checkmark.circle.fill",
                             text: "Domain Models",
                             color: .green)
                    StatusRow(icon: "checkmark.circle.fill",
                             text: "Core Data Entities",
                             color: .green)
                    StatusRow(icon: "checkmark.circle.fill",
                             text: "Persistence Layer",
                             color: .green)
                    StatusRow(icon: "circle.dashed",
                             text: "Service Layer (Phase 3A Spec 2)",
                             color: .orange)
                    StatusRow(icon: "circle.dashed",
                             text: "UI & ViewModels (Phase 3A Spec 3)",
                             color: .orange)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)

                Spacer()
            }
            .padding()
            .navigationTitle("Personal AI")
        }
    }
}

struct StatusRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            Text(text)
                .font(.body)
            Spacer()
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
