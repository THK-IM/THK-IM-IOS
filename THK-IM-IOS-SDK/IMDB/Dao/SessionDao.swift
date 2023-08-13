//
//  SessionDao.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/14.
//

import Foundation
import WCDBSwift

protocol SessionDao {
    
    func updateSessions(_ sessions: Session...) throws
    
    func insertSessions(_ sessions: Session...) throws
    
    func querySessionById(_ sId: Int64) throws -> Session?
    
    func querySessionByEntityId(_ entityId: Int64, _ type: Int) throws -> Session?
    
    func querySessions(_ count: Int, _ mTime: Int64) throws -> Array<Session>?
}

class innerSessionDao : SessionDao {
    
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
    
    func insertSessions(_ sessions: Session...) throws {
        try self.database?.insertOrIgnore(sessions, intoTable: self.tableName)
    }
    
    func querySessionById(_ sId: Int64) throws -> Session? {
        return try self.database?.getObject(fromTable: self.tableName, where: Session.Properties.id == sId)
    }
    
    func querySessionByEntityId(_ entityId: Int64, _ type: Int) throws -> Session? {
        return try self.database?.getObject(fromTable: self.tableName, where: Session.Properties.entityId == entityId && Session.Properties.type == type)
    }
    
    func querySessions(_ count: Int, _ mTime: Int64) throws -> Array<Session>? {
        return try self.database?.getObjects(
            fromTable: self.tableName,
            where: Session.Properties.mTime < mTime,
            orderBy: [Session.Properties.mTime.order(Order.descending)],
            limit: count
        )
    }
}
