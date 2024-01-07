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
    
    //    public func findByIds(_ ids: Set<Int64>) -> [Contact]? {
    //        var contactIds = [Int64]()
    //        for id in ids {
    //            contactIds.append(id)
    //        }
    //        return try? self.database?.getObjects(fromTable: self.tableName, where: Contact.Properties.id.in(contactIds))
    //    }
    
    
}
