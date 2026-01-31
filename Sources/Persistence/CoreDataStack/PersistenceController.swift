//
//  PersistenceController.swift
//  PersonalAI
//
//  Phase 3A Spec 1: Core Data Stack Manager
//  Manages NSPersistentContainer lifecycle and provides contexts
//

import CoreData

/// Manages the Core Data stack for the application
struct PersistenceController: Sendable {
    /// Shared instance for production use
    static let shared = PersistenceController()

    /// Preview instance with in-memory store for SwiftUI previews
    static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext

        // Create sample data for previews
        do {
            let sampleThought = Thought(
                id: UUID(),
                userId: UUID(),
                content: "Sample thought for preview",
                tags: ["preview", "sample"],
                status: .active,
                context: Context(
                    timestamp: Date(),
                    location: nil,
                    timeOfDay: .morning,
                    energy: .high,
                    focusState: .deep_work,
                    calendar: nil,
                    activity: nil,
                    weather: nil,
                    stateOfMind: nil
                ),
                createdAt: Date(),
                updatedAt: Date(),
                classification: nil,
                relatedThoughtIds: [],
                taskId: nil
            )

            _ = try sampleThought.toEntity(in: viewContext)
            try viewContext.save()
        } catch {
            // Preview sample data creation is best-effort
            print("Failed to create preview data: \(error)")
        }

        return controller
    }()

    /// The persistent container for the application
    let container: NSPersistentContainer

    /// Initializes the persistence controller
    /// - Parameter inMemory: If true, creates an in-memory store (useful for testing and previews)
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "PersonalAI")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Enable automatic lightweight migration for schema changes
            // This allows Core Data to automatically migrate when we add new fields
            if let description = container.persistentStoreDescriptions.first {
                description.shouldMigrateStoreAutomatically = true
                description.shouldInferMappingModelAutomatically = true
            }
        }

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // In production, handle this error appropriately
                // For now, fatal error for development
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }

        // Configure for better performance and thread safety
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }

    /// Saves the view context if there are changes
    func save() throws {
        let context = container.viewContext
        if context.hasChanges {
            try context.save()
        }
    }

    /// Creates a new background context for performing work off the main thread
    func newBackgroundContext() -> NSManagedObjectContext {
        return container.newBackgroundContext()
    }
}
