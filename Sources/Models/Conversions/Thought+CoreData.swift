//
//  Thought+CoreData.swift
//  STASH
//
//  Phase 3A Spec 1: Data Models & Persistence
//  Bidirectional conversion between Thought and ThoughtEntity
//

import Foundation
import CoreData

extension Thought {
    /// Converts this Swift struct to a Core Data entity.
    ///
    /// Creates a new `ThoughtEntity` in the given managed object context.
    /// Handles conversion of:
    /// - Tags array → JSON data
    /// - Context struct → JSON data
    /// - Classification struct → ClassificationEntity relationship
    /// - Related thought IDs → NSSet of ThoughtEntity objects
    ///
    /// - Parameter context: The Core Data managed object context
    /// - Returns: A new `ThoughtEntity` instance
    /// - Throws: `ConversionError` if JSON encoding fails or required data is missing
    nonisolated func toEntity(in context: NSManagedObjectContext) throws -> ThoughtEntity {
        let entity = ThoughtEntity(context: context)
        entity.id = self.id
        entity.userId = self.userId
        entity.content = self.content

        // Encode attributed content if present (iOS 15+)
        if let attributedContent = self.attributedContent {
            let nsAttributed = NSAttributedString(attributedContent)
            entity.attributedContentData = try? NSKeyedArchiver.archivedData(withRootObject: nsAttributed, requiringSecureCoding: true)
        }

        entity.status = self.status.rawValue
        entity.createdAt = self.createdAt
        entity.updatedAt = self.updatedAt
        entity.taskId = self.taskId
        entity.isShiny = self.isShiny as NSNumber

        // Encode tags as JSON
        do {
            entity.tagsJSON = try JSONEncoder().encode(self.tags)
        } catch {
            throw ConversionError.invalidJSONData("tags")
        }

        // Encode context as JSON
        do {
            entity.contextJSON = try JSONEncoder().encode(self.context)
        } catch {
            throw ConversionError.invalidJSONData("context")
        }

        // Handle classification (one-to-one)
        if let classification = self.classification {
            entity.classification = try classification.toEntity(in: context)
            entity.classification?.thought = entity
        }

        // Handle related thoughts (many-to-many)
        if !self.relatedThoughtIds.isEmpty {
            let fetchRequest = NSFetchRequest<ThoughtEntity>(entityName: "ThoughtEntity")
            fetchRequest.predicate = NSPredicate(format: "id IN %@", self.relatedThoughtIds)

            do {
                let relatedEntities = try context.fetch(fetchRequest)
                entity.relatedThoughts = NSSet(array: relatedEntities)

                // Set bidirectional relationships
                for relatedEntity in relatedEntities {
                    relatedEntity.addToRelatedThoughts(entity)
                }
            } catch {
                throw ConversionError.corruptedRelationship("Failed to fetch related thoughts: \(error.localizedDescription)")
            }
        }

        return entity
    }

    /// Creates a Swift struct from a Core Data entity.
    ///
    /// Extracts data from `ThoughtEntity` and converts:
    /// - JSON tags → String array
    /// - JSON context → Context struct
    /// - ClassificationEntity → Classification struct
    /// - NSSet of ThoughtEntity → Array of UUIDs
    ///
    /// - Parameter entity: The Core Data entity to convert
    /// - Returns: A new `Thought` instance
    /// - Throws: `ConversionError` if JSON decoding fails or required data is missing
    nonisolated static func from(_ entity: ThoughtEntity) throws -> Thought {
        // Decode tags from JSON
        let tags: [String]
        do {
            tags = try JSONDecoder().decode([String].self, from: entity.tagsJSON)
        } catch {
            throw ConversionError.invalidJSONData("tags")
        }

        // Decode context from JSON
        let context: Context
        do {
            context = try JSONDecoder().decode(Context.self, from: entity.contextJSON)
        } catch {
            throw ConversionError.invalidJSONData("context")
        }

        // Parse status
        guard let status = ThoughtStatus(rawValue: entity.status) else {
            throw ConversionError.typeMismatch("Invalid ThoughtStatus: \(entity.status)")
        }

        // Convert classification (one-to-one)
        let classification: Classification?
        if let classificationEntity = entity.classification {
            classification = try Classification.from(classificationEntity)
        } else {
            classification = nil
        }

        // Extract related thought IDs (many-to-many)
        let relatedThoughtIds: [UUID]
        if let relatedSet = entity.relatedThoughts as? Set<ThoughtEntity> {
            relatedThoughtIds = relatedSet.map { $0.id }.sorted(by: { $0.uuidString < $1.uuidString })
        } else {
            relatedThoughtIds = []
        }

        // Decode attributed content if available (iOS 15+)
        let attributedContent: AttributedString?
        if let data = entity.attributedContentData,
           let nsAttributed = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSAttributedString.self, from: data) {
            attributedContent = AttributedString(nsAttributed)
        } else {
            attributedContent = nil
        }

        return Thought(
            id: entity.id,
            userId: entity.userId,
            content: entity.content,
            attributedContent: attributedContent,
            tags: tags,
            status: status,
            context: context,
            createdAt: entity.createdAt,
            updatedAt: entity.updatedAt,
            classification: classification,
            relatedThoughtIds: relatedThoughtIds,
            taskId: entity.taskId,
            isShiny: entity.isShiny?.boolValue ?? false
        )
    }
}
