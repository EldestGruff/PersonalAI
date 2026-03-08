//
//  AcornSpendRecord.swift
//  STASH
//
//  CoreData entity for the acorn spend ledger.
//
//  Phase 3B: Part of the split-ledger architecture where
//  currentBalance = lifetimeEarned (KV Store) − sum(AcornSpendRecords) (CoreData/CloudKit).
//  This append-only design prevents spend-race conflicts across devices.
//

import Foundation
import CoreData

/// Records a single acorn spend event. Append-only — never modified after creation.
///
/// Synced via NSPersistentCloudKitContainer so spend events appear on all devices.
/// `currentBalance` is always derived as `lifetimeEarned - sum(all records.amount)`.
@objc(AcornSpendRecord)
public final class AcornSpendRecord: NSManagedObject {
    /// Unique identifier for this spend event
    @NSManaged public var id: UUID

    /// Number of acorns spent (always positive)
    @NSManaged public var amount: Int32

    /// Human-readable reason (e.g. "accessory.wizard_hat", "migration.opening_balance")
    @NSManaged public var reason: String?

    /// When the spend occurred
    @NSManaged public var createdAt: Date

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AcornSpendRecord> {
        return NSFetchRequest<AcornSpendRecord>(entityName: "AcornSpendRecord")
    }
}
