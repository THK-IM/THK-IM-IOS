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
        var sessionId: Int64 = 0
        var memberIds = [Int64]()
        for member in members {
            sessionId = member.sessionId
            memberIds.append(member.userId)
        }
        try self.database?.delete(
            fromTable: self.tableName,
            where: SessionMember.Properties.sessionId == sessionId && SessionMember.Properties.userId.in(memberIds)
        )
    }
    
    public func findBySessionId(_ sessionId: Int64) -> Array<SessionMember> {
        let members: Array<SessionMember>? = try? self.database?.getObjects(
            fromTable: self.tableName,
            where: SessionMember.Properties.sessionId == sessionId
        ) 
        return members ?? Array<SessionMember>()
    }
    
    
}

