//
//  DefaultContactDao.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation
import WCDBSwift

open class DefaultContactDao : ContactDao {
    
    weak var database: Database?
    let tableName: String
    
    init(_ database: Database, _ tableName: String) {
        self.database = database
        self.tableName = tableName
    }
    
    
    public func insertOrReplace(_ contacts: [Contact]) throws {
        try self.database?.insertOrReplace(contacts, intoTable: self.tableName)
    }
    
    public func insertOrIgnore(_ contacts: [Contact]) throws {
        try self.database?.insertOrIgnore(contacts, intoTable: self.tableName)
    }
    
    
    public func findAll() -> Array<Contact> {
        let contacts: Array<Contact>? = try? self.database?.getObjects(
            fromTable: self.tableName,
            orderBy: [Contact.Properties.cTime.order(Order.descending)]
        )
        return contacts ?? Array<Contact>()
    }
    
    
    public func findByUserId(_ contactId: Int64) -> Contact? {
        return try? self.database?.getObject(
            fromTable: self.tableName,
            where: Contact.Properties.id == contactId
        )
    }
    
    public func findByUserIds(_ ids: Array<Int64>) -> Array<Contact> {
        let contacts: Array<Contact>? = try? self.database?.getObjects(
            fromTable: self.tableName,
            where: Contact.Properties.id.in(ids)
        )
        return contacts ?? Array<Contact>()
    }
    
    public func findByRelation(_ relation: Int) -> Array<Contact> {
        let contacts: Array<Contact>? = try? self.database?.getObjects(
            fromTable: self.tableName,
            where: Contact.Properties.relation & relation != 0,
            orderBy: [Contact.Properties.mTime.order(Order.descending)]
        )
        return contacts ?? Array<Contact>()
    }
    
    
}
