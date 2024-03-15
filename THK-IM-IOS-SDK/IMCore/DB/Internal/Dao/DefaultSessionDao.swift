//
//  DefaultSessionDao.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/22.
//

import Foundation
import WCDBSwift



open class DefaultSessionDao : SessionDao {
    
    weak var database: Database?
    let tableName: String
    
    init(_ database: Database, _ tableName: String) {
        self.database = database
        self.tableName = tableName
    }
    
    public func insertOrUpdate(_ sessions: [Session]) throws {
        try self.database?.insertOrReplace(sessions, intoTable: self.tableName)
    }
    
    public func insertOrIgnore(_ sessions: [Session]) throws {
        try self.database?.insertOrIgnore(sessions, intoTable: self.tableName)
    }
    
    public func delete(_ sessions: [Session]) throws {
        var ids = Array<Int64>()
        for session in sessions {
            ids.append(session.id)
        }
        try self.database?.delete(fromTable: self.tableName, where: Session.Properties.id.in(ids))
    }
    
    public func update(_ sessions: [Session]) throws {
        for session in sessions {
            try self.database?.update(
                table: self.tableName,
                on: Session.Properties.all,
                with: session,
                where: Session.Properties.id == session.id
            )
        }
    }
    
    /**
     * 更新session消息同步时间
     */
    public func updateMsgSyncTime(_ sessionId: Int64, _ time: Int64) throws {
        try self.database?.update(
            table: self.tableName,
            on: Session.Properties.msgSyncTime,
            with: time,
            where: Session.Properties.id == sessionId
        )
    }
    
    /**
     * 更新session成员同步时间
     */
    public func updateMemberSyncTime(_ sessionId: Int64, _ time: Int64) throws {
        try self.database?.update(
            table: self.tableName,
            on: Session.Properties.memberSyncTime,
            with: time,
            where: Session.Properties.id == sessionId
        )
    }
    
    
    /**
     * 设置session草稿
     */
    public func updateSessionDraft(_ sessionId: Int64, _ draft: String?) throws {
        try self.database?.update(
            table: self.tableName,
            on: Session.Properties.draft,
            with: draft ?? "",
            where: Session.Properties.id == sessionId
        )
    }
    
    
    /**
     * 查询session消息同步时间
     */
    public func findMsgSyncTimeById(_ sessionId: Int64) -> Int64 {
        guard let res = try? self.database?.getValue(
            on: Session.Properties.msgSyncTime,
            fromTable: self.tableName,
            where: Session.Properties.id == sessionId
        ).int64Value else {
            return 0
        }
        return Int64(res)
    }
    
    public func findMemberSyncTimeById(_ sessionId: Int64) -> Int64 {
        guard let res = try? self.database?.getValue(
            on: Session.Properties.memberSyncTime,
            fromTable: self.tableName,
            where: Session.Properties.id == sessionId
        ).int64Value else {
            return 0
        }
        return Int64(res)
    }
    
    
    public func findById(_ sId: Int64) throws -> Session? {
        return try self.database?.getObject(fromTable: self.tableName, where: Session.Properties.id == sId && Session.Properties.deleted == 0)
    }
    
    public func findByEntityId(_ entityId: Int64, _ type: Int) throws -> Session? {
        return try self.database?.getObject(fromTable: self.tableName, where: Session.Properties.entityId == entityId && Session.Properties.type == type && Session.Properties.deleted == 0)
    }
    
    public func findByParentId(_ parentId: Int64, _ count: Int, _ mTime: Int64) throws -> Array<Session>? {
        return try self.database?.getObjects(
            fromTable: self.tableName,
            where: Session.Properties.parentId == parentId && Session.Properties.id != parentId && Session.Properties.mTime < mTime
            && Session.Properties.deleted == 0,
            orderBy: [Session.Properties.topTimestamp.order(Order.descending), Session.Properties.mTime.order(Order.descending)],
            limit: count
        )
    }
    
    public func findAll(_ type: Int) throws -> Array<Session>? {
        return try self.database?.getObjects(
            fromTable: self.tableName,
            where: Session.Properties.type == type && Session.Properties.deleted == 0,
            orderBy: [Session.Properties.topTimestamp.order(Order.descending), Session.Properties.mTime.order(Order.descending)]
        )
    }
    
    public func findUnreadSessions(_ parentInd: Int64) throws -> Array<Session>? {
        return try self.database?.getObjects(
            fromTable: self.tableName,
            where: Session.Properties.parentId == parentInd &&
            Session.Properties.unreadCount > 0 && Session.Properties.deleted == 0
        )
    }
}

