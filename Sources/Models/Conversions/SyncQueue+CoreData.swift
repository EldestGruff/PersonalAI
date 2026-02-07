//
//  SyncQueue+CoreData.swift
//  STASH
//
//  Phase 3A Spec 1: Data Models & Persistence
//  Bidirectional conversion between SyncQueueItem and SyncQueueEntity
//

import Foundation
import CoreData

extension SyncQueueItem {
    /// Converts this Swift struct to a Core Data entity.
    ///
    /// - Parameter context: The Core Data managed object context
    /// - Returns: A new `SyncQueueEntity` instance
    /// - Throws: `ConversionError` if conversion fails
    nonisolated func toEntity(in context: NSManagedObjectContext) throws -> SyncQueueEntity {
        let entity = SyncQueueEntity(context: context)
        entity.id = self.id
        entity.entityType = self.entity.rawValue
        entity.entityId = self.entityId
        entity.action = self.action.rawValue
        entity.payload = self.payload
        entity.retries = Int32(self.retries)
        entity.lastError = self.lastError
        entity.createdAt = self.createdAt
        entity.nextRetryAt = self.nextRetryAt
        entity.backendResponseId = self.backendResponseId

        return entity
    }

    /// Creates a Swift struct from a Core Data entity.
    ///
    /// - Parameter entity: The Core Data entity to convert
    /// - Returns: A new `SyncQueueItem` instance
    /// - Throws: `ConversionError` if conversion fails
    nonisolated static func from(_ entity: SyncQueueEntity) throws -> SyncQueueItem {
        // Parse enums
        guard let syncEntity = SyncEntity(rawValue: entity.entityType) else {
            throw ConversionError.typeMismatch("Invalid SyncEntity: \(entity.entityType)")
        }
        guard let syncAction = SyncAction(rawValue: entity.action) else {
            throw ConversionError.typeMismatch("Invalid SyncAction: \(entity.action)")
        }

        return SyncQueueItem(
            id: entity.id,
            entity: syncEntity,
            entityId: entity.entityId,
            action: syncAction,
            payload: entity.payload,
            retries: Int(entity.retries),
            lastError: entity.lastError,
            createdAt: entity.createdAt,
            nextRetryAt: entity.nextRetryAt,
            backendResponseId: entity.backendResponseId
        )
    }
}
