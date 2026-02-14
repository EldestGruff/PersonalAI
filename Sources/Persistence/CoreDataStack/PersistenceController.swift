//
//  PersistenceController.swift
//  STASH
//
//  Core Data + CloudKit stack manager.
//  NSPersistentCloudKitContainer handles device-to-device sync via iCloud automatically.
//  All entities marked syncable="YES" in the model are mirrored to CloudKit.
//
//  Architecture:
//  - CloudKit sync: thoughts, classifications, tasks, fine-tuning data
//  - Local-only:    server enrichment queue (SyncQueueEntity) — queues work
//                   for the personal server (AI inference, vector indexing, etc.)
//                   These items are device-local by design; each device manages its own queue.
//

import CoreData

/// Manages the Core Data + CloudKit stack for the application.
struct PersistenceController: Sendable {

    // MARK: - Shared Instances

    /// Shared instance for production use
    static let shared = PersistenceController()

    /// Preview instance with in-memory store for SwiftUI previews
    static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext

        do {
            let sampleThought = Thought(
                id: UUID(),
                userId: UUID(),
                content: "Sample thought for preview",
                attributedContent: nil,
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
                    stateOfMind: nil,
                    energyBreakdown: nil
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
            print("Failed to create preview data: \(error)")
        }

        return controller
    }()

    // MARK: - Container

    /// The persistent container — NSPersistentCloudKitContainer for production,
    /// NSPersistentContainer for in-memory previews.
    let container: NSPersistentContainer

    // MARK: - Initialization

    init(inMemory: Bool = false) {
        if inMemory {
            // Use a plain container for previews — no CloudKit connection needed
            let previewContainer = NSPersistentContainer(name: "STASH")
            previewContainer.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
            previewContainer.loadPersistentStores { _, error in
                if let error {
                    fatalError("Failed to load preview store: \(error)")
                }
            }
            previewContainer.viewContext.automaticallyMergesChangesFromParent = true
            previewContainer.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
            container = previewContainer
        } else {
            container = Self.makeCloudKitContainer()
        }
    }

    // MARK: - CloudKit Container Setup

    private static func makeCloudKitContainer() -> NSPersistentCloudKitContainer {
        let ckContainer = NSPersistentCloudKitContainer(name: "STASH")

        guard let description = ckContainer.persistentStoreDescriptions.first else {
            fatalError("No persistent store description found")
        }

        // CloudKit container — must match the identifier in Xcode Signing & Capabilities
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.com.withershins.stash"
        )

        // Required for CloudKit: persistent history lets the container track changes
        // that need to be pushed to / pulled from iCloud
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)

        // Post a notification whenever remote changes arrive from CloudKit so the
        // UI can refresh without polling
        description.setOption(
            true as NSNumber,
            forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey
        )

        // Lightweight migration for future schema changes
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true

        ckContainer.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                handleLoadError(error, storeDescription: storeDescription, container: ckContainer)
            }
        }

        // Automatically merge changes arriving from CloudKit into the view context
        ckContainer.viewContext.automaticallyMergesChangesFromParent = true

        // Last-write-wins per property — safe for concurrent edits across devices
        ckContainer.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump

        return ckContainer
    }

    // MARK: - Error Handling

    private static func handleLoadError(
        _ error: NSError,
        storeDescription: NSPersistentStoreDescription,
        container: NSPersistentCloudKitContainer
    ) {
        NSLog("⚠️ Core Data load error: \(error), \(error.userInfo)")

        let migrationCodes: Set<Int> = [
            134100, // NSPersistentStoreIncompatibleVersionHashError
            134130, // NSMigrationMissingSourceModelError
            134140  // NSMigrationError
        ]

        guard error.domain == NSCocoaErrorDomain,
              migrationCodes.contains(error.code),
              let storeURL = storeDescription.url else {
            fatalError("Unresolved Core Data error: \(error)")
        }

        NSLog("🔄 Migration error — deleting and recreating store")

        let fm = FileManager.default
        let base = storeURL.deletingLastPathComponent()
        let name = storeURL.lastPathComponent
        try? fm.removeItem(at: storeURL)
        try? fm.removeItem(at: base.appendingPathComponent(name + "-shm"))
        try? fm.removeItem(at: base.appendingPathComponent(name + "-wal"))

        container.loadPersistentStores { _, retryError in
            if let retryError {
                fatalError("Failed to recreate store: \(retryError)")
            }
            NSLog("✅ Store recreated successfully")
        }
    }

    // MARK: - Public API

    /// Saves the view context if there are pending changes
    func save() throws {
        let context = container.viewContext
        if context.hasChanges {
            try context.save()
        }
    }

    /// Creates a background context for off-main-thread work
    func newBackgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }
}

// MARK: - CloudKit Sync Status

extension PersistenceController {

    /// Subscribe to this notification to know when remote CloudKit changes have
    /// been merged into the view context. Useful for refreshing UI or re-running
    /// searches after a sync event.
    ///
    /// Usage:
    /// ```swift
    /// .onReceive(PersistenceController.remoteChangeNotification) { _ in
    ///     // refresh UI
    /// }
    /// ```
    static let remoteChangeNotification = Notification.Name(
        NSPersistentStoreRemoteChangeNotificationPostOptionKey
    )
}
