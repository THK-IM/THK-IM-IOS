//
//  DefaultSessionDao.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/22.
//

import Foundation
import WCDBSwift



class DefaultSessionDao : SessionDao {
    
    weak var database: Database?
    let tableName: String
    
    init(_ database: Database, _ tableName: String) {
        self.database = database
        self.tableName = tableName
    }
    
    func updateSessions(_ sessions: Session...) throws {
        for session in sessions {
            try self.database?.update(
                table: self.tableName,
                on: Session.Properties.all,
                with: session,
                where: Session.Properties.id == session.id
            )
        }
    }
    
    func insertOrUpdateSessions(_ sessions: Session...) throws {
        try self.database?.insertOrReplace(sessions, intoTable: self.tableName)
    }
    
    func insertOrIgnoreSessions(_ sessions: Session...) throws {
        try self.database?.insertOrIgnore(sessions, intoTable: self.tableName)
    }
    
    func deleteSessions(_ sessions: Session...) throws {
        var ids = Array<Int64>()
        for session in sessions {
            ids.append(session.id)
        }
        try self.database?.delete(fromTable: self.tableName, where: Session.Properties.id.in(ids))
    }
    
    func findSessionById(_ sId: Int64) throws -> Session? {
        return try self.database?.getObject(fromTable: self.tableName, where: Session.Properties.id == sId)
    }
    
    func findSessionByEntityId(_ entityId: Int64, _ type: Int) throws -> Session? {
        return try self.database?.getObject(fromTable: self.tableName, where: Session.Properties.entityId == entityId && Session.Properties.type == type)
    }
    
    func findSessions(_ parentId: Int64, _ count: Int, _ mTime: Int64) throws -> Array<Session>? {
        return try self.database?.getObjects(
            fromTable: self.tableName,
            where: Session.Properties.parentId == parentId && Session.Properties.mTime < mTime,
            orderBy: [Session.Properties.topTimestamp.order(Order.descending), Session.Properties.mTime.order(Order.descending)],
            limit: count
        )
    }
}

