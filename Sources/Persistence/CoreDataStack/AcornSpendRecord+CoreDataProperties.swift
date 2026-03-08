//
//  AcornSpendRecord+CoreDataProperties.swift
//  STASH
//
//  Created by Andy Fenner on 3/7/26.
//
//

public import Foundation
public import CoreData


public typealias AcornSpendRecordCoreDataPropertiesSet = NSSet

extension AcornSpendRecord {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AcornSpendRecord> {
        return NSFetchRequest<AcornSpendRecord>(entityName: "AcornSpendRecord")
    }

    @NSManaged public var amount: Int32
    @NSManaged public var createdAt: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var reason: String?

}

extension AcornSpendRecord : Identifiable {

}
