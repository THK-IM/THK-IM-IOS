//
//  DefaultSessionMemberDao.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation
import WCDBSwift

open class DefaultSessionMemberDao: SessionMemberDao {
    
    weak var database: Database?
    let tableName: String
    
    init(_ database: Database, _ tableName: String) {
        self.database = database
        self.tableName = tableName
    }
    
    public func insertOrReplace(_ members: [SessionMember]) throws {
        try self.database?.insertOrReplace(members, intoTable: self.tableName)
    }
    
    public func insertOrIgnore(_ members: [SessionMember]) throws {
        try self.database?.insertOrIgnore(members, intoTable: self.tableName)
    }
    
    public func delete(_ members: [SessionMember]) throws {
        var deleteMembers = [SessionMember]()
        for m in members {
            m.deleted = 1
            deleteMembers.append(m)
        }
        try self.database?.insertOrReplace(deleteMembers, intoTable: self.tableName)
    }
    
    
    public func findSessionMember(_ sessionId: Int64, _ userId: Int64) -> SessionMember? {
        return try? self.database?.getObject(
            fromTable: self.tableName,
            where: SessionMember.Properties.sessionId == sessionId
            && SessionMember.Properties.userId == userId
        )
    }
    
    public func findBySessionId(_ sessionId: Int64) -> Array<SessionMember> {
        let members: Array<SessionMember>? = try? self.database?.getObjects(
            fromTable: self.tableName,
            where: SessionMember.Properties.sessionId == sessionId
        )
        return members ?? Array<SessionMember>()
    }
    
    
    public func findSessionMemberCount(_ sessionId: Int64) -> Int {
        if let count = try? self.database?.getValue(
            on: SessionMember.Properties.userId.count(),
            fromTable: self.tableName,
            where: SessionMember.Properties.sessionId == sessionId 
            && SessionMember.Properties.deleted == 0
        ).int32Value {
            return Int(count)
        }
        return 0
    }
    
    
}

