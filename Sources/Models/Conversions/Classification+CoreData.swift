//
//  Classification+CoreData.swift
//  PersonalAI
//
//  Phase 3A Spec 1: Data Models & Persistence
//  Bidirectional conversion between Classification and ClassificationEntity
//

import Foundation
import CoreData

extension Classification {
    /// Converts this Swift struct to a Core Data entity.
    ///
    /// - Parameter context: The Core Data managed object context
    /// - Returns: A new `ClassificationEntity` instance
    /// - Throws: `ConversionError` if JSON encoding fails
    nonisolated func toEntity(in context: NSManagedObjectContext) throws -> ClassificationEntity {
        let entity = ClassificationEntity(context: context)
        entity.id = self.id
        entity.type = self.type.rawValue
        entity.confidence = self.confidence
        entity.sentiment = self.sentiment.rawValue
        entity.language = self.language
        entity.processingTime = self.processingTime
        entity.model = self.model
        entity.createdAt = self.createdAt

        // Encode entities as JSON
        do {
            entity.entitiesJSON = try JSONEncoder().encode(self.entities)
        } catch {
            throw ConversionError.invalidJSONData("entities")
        }

        // Encode suggested tags as JSON
        do {
            entity.suggestedTagsJSON = try JSONEncoder().encode(self.suggestedTags)
        } catch {
            throw ConversionError.invalidJSONData("suggestedTags")
        }

        // Encode parsed date/time as JSON (if present)
        if let parsedDateTime = self.parsedDateTime {
            do {
                entity.parsedDateTimeJSON = try JSONEncoder().encode(parsedDateTime)
            } catch {
                throw ConversionError.invalidJSONData("parsedDateTime")
            }
        } else {
            entity.parsedDateTimeJSON = nil
        }

        return entity
    }

    /// Creates a Swift struct from a Core Data entity.
    ///
    /// - Parameter entity: The Core Data entity to convert
    /// - Returns: A new `Classification` instance
    /// - Throws: `ConversionError` if JSON decoding fails
    nonisolated static func from(_ entity: ClassificationEntity) throws -> Classification {
        // Decode entities from JSON
        let entities: [String]
        do {
            entities = try JSONDecoder().decode([String].self, from: entity.entitiesJSON)
        } catch {
            throw ConversionError.invalidJSONData("entities")
        }

        // Decode suggested tags from JSON
        let suggestedTags: [String]
        do {
            suggestedTags = try JSONDecoder().decode([String].self, from: entity.suggestedTagsJSON)
        } catch {
            throw ConversionError.invalidJSONData("suggestedTags")
        }

        // Parse enums
        guard let type = ClassificationType(rawValue: entity.type) else {
            throw ConversionError.typeMismatch("Invalid ClassificationType: \(entity.type)")
        }
        guard let sentiment = Sentiment(rawValue: entity.sentiment) else {
            throw ConversionError.typeMismatch("Invalid Sentiment: \(entity.sentiment)")
        }

        // Decode parsed date/time from JSON (if present)
        let parsedDateTime: ParsedDateTime?
        if let parsedDateTimeJSON = entity.parsedDateTimeJSON {
            do {
                parsedDateTime = try JSONDecoder().decode(ParsedDateTime.self, from: parsedDateTimeJSON)
            } catch {
                throw ConversionError.invalidJSONData("parsedDateTime")
            }
        } else {
            parsedDateTime = nil
        }

        return Classification(
            id: entity.id,
            type: type,
            confidence: entity.confidence,
            entities: entities,
            suggestedTags: suggestedTags,
            sentiment: sentiment,
            language: entity.language,
            processingTime: entity.processingTime,
            model: entity.model,
            createdAt: entity.createdAt,
            parsedDateTime: parsedDateTime
        )
    }
}
