//
//  DefaultGroupDao.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation
import WCDBSwift

open class DefaultGroupDao: GroupDao {
    
    
    weak var database: Database?
    let tableName: String
    
    init(_ database: Database, _ tableName: String) {
        self.database = database
        self.tableName = tableName
    }
    
    public func insertOrReplace(_ groups: Group...) throws {
        try self.database?.insertOrReplace(groups, intoTable: self.tableName)
    }
    
    public func insertOrIgnore(_ groups: Group...) throws {
        try self.database?.insertOrIgnore(groups, intoTable: self.tableName)
    }
    
    public func deleteByIds(_ ids: Set<Int64>) throws {
        var groupIds = [Int64]()
        for id in ids {
            groupIds.append(id)
        }
        try self.database?.delete(
            fromTable: self.tableName,
            where: Group.Properties.id.in(groupIds)
        )
    }
    
    public func findAll() -> [Group]? {
        return try? self.database?.getObjects(
            fromTable: self.tableName,
            orderBy: [Group.Properties.cTime.order(Order.descending)]
        )
    }
    
    public func findById(_ id: Int64) -> Group? {
        return try? self.database?.getObject(fromTable: self.tableName, where: Group.Properties.id == id)
    }
    
    
}
