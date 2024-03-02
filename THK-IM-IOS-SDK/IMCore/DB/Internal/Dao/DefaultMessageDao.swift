//
//  DefaultMessageDao.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/22.
//

import Foundation
import WCDBSwift
import CocoaLumberjack

open class DefaultMessageDao : MessageDao {
    
    weak var database: Database?
    let tableName: String
    
    init(_ database: Database, _ tableName: String) {
        self.database = database
        self.tableName = tableName
    }
    
    public func insertOrReplace(_ messages: [Message]) throws {
        try self.database?.insertOrReplace(messages, intoTable: self.tableName)
    }
    
    public func insertOrIgnore(_ messages: [Message]) throws {
        try self.database?.insertOrIgnore(messages, intoTable: self.tableName)
    }
    
    public func update(_ messages: Message...) throws {
        for message in messages {
            try self.database?.update(
                table: self.tableName,
                on: Message.Properties.all,
                with: message,
                where: Message.Properties.id == message.id && Message.Properties.fromUId == message.fromUId
            )
        }
    }
    
    public func updateMsgData(_ sessionId: Int64, _ id: Int64, _ fromUId: Int64, _ data: String) throws {
        let update = StatementUpdate().update(table:self.tableName)
            .set(Message.Properties.data)
            .to(data)
            .where(
                Message.Properties.sessionId == sessionId
                && Message.Properties.id == id
                && Message.Properties.fromUId == fromUId
            )
        try self.database?.exec(update)
    }
    
    public func updateOperationStatus(_ sessionId: Int64, _ msgIds: [Int64], _ operateStatus: Int) throws {
        let operateStatusColumn = Column(named: "opr_status")
        let expression1 = Expression(with: operateStatusColumn)
        let expression2 = Expression(with: operateStatus)
        let expression3 = expression1 | expression2
        
        let update = StatementUpdate().update(table:self.tableName)
            .set(Message.Properties.operateStatus)
            .to(expression3)
            .where(
                Message.Properties.sessionId == sessionId
                && Message.Properties.msgId.in(msgIds)
            )
        try self.database?.exec(update)
    }
    
    /**
     * 重置消息发送状态为失败
     */
    public func resetSendStatusFailed() throws {
        let update = StatementUpdate()
            .update(table:self.tableName)
            .set(Message.Properties.sendStatus)
            .to(MsgSendStatus.Failed.rawValue)
            .where(
                Message.Properties.sendStatus != MsgSendStatus.Success.rawValue
            )
        try self.database?.exec(update)
    }
    
    
    /**
     * 获取session下的未读数
     */
    public func getUnReadCount(_ sessionId: Int64) throws -> Int64 {
        guard let res = try self.database?.getValue(
            on: Message.Properties.msgId.count(),
            fromTable: self.tableName,
            where: Message.Properties.sessionId == sessionId &&
            (Message.Properties.type > 0) &&
            (Message.Properties.operateStatus & MsgOperateStatus.ClientRead.rawValue != 2)
        ).int32Value else {
            return 0
        }
        return Int64(res)
    }
    
    
    /**
     * 更新消息发送状态
     */
    public func updateSendStatus(_ sessionId: Int64, _ id: Int64, _ fromUId: Int64, _ status: Int) throws {
        let update = StatementUpdate()
            .update(table:self.tableName)
            .set(Message.Properties.sendStatus)
            .to(status)
            .where(
                Message.Properties.sessionId == sessionId &&
                Message.Properties.id == id &&
                Message.Properties.fromUId == fromUId
            )
        try self.database?.exec(update)
    }
    
    
    public func delete(_ messages: Message...) throws {
        var ids = Array<Int64>()
        for message in messages {
            ids.append(message.id)
        }
        try self.database?.delete(fromTable: self.tableName, where: Message.Properties.id.in(ids))
    }
    
    public func delete(_ messages: [Message]) throws {
        var ids = Array<Int64>()
        for message in messages {
            ids.append(message.id)
        }
        try self.database?.delete(fromTable: self.tableName, where: Message.Properties.id.in(ids))
    }
    
    public func deleteByCTimeExclude(_ startTime: Int64, _ endTime: Int64) throws {
        try self.database?.delete(
            fromTable: self.tableName,
            where: Message.Properties.cTime < startTime || Message.Properties.cTime > endTime
        )
    }
    
    public func deleteByIncludeCTime(_ startTime: Int64, _ endTime: Int64) throws {
        try self.database?.delete(
            fromTable: self.tableName,
            where: Message.Properties.cTime >= startTime && Message.Properties.cTime <= endTime
        )
    }
    
    /**
     * 删除session下的所有消息
     */
    public func deleteBySessionId(_ sessionId: Int64) throws {
        try self.database?.delete(
            fromTable: self.tableName,
            where: Message.Properties.sessionId == sessionId
        )
    }
    
    
    public func deleteBySessionIds(_ sessionIds: Set<Int64>) throws {
        var sIds = [Int64]()
        for sessionId in sessionIds {
            sIds.append(sessionId)
        }
        try self.database?.delete(
            fromTable: self.tableName,
            where: Message.Properties.sessionId.in(sIds)
        )
    }
    
    /**
     * 查找发送中的消息
     */
    public func findSendingMessages(successStatus: Int) -> Array<Message> {
        let message: Array<Message>? = try? self.database?.getObjects(
            fromTable: self.tableName,
            where: Message.Properties.sendStatus < successStatus,
            orderBy: [Message.Properties.cTime.order(Order.ascending)]
        )
        return message ?? Array<Message>()
    }
    
    public func findSessionMessageCount(_ sessionId: Int64) throws -> Int64 {
        return try self.database!.getValue(
            on: Message.Properties.msgId.count(),
            fromTable: self.tableName,
            where: Message.Properties.sessionId == sessionId
        ).int64Value
    }
    
    
    public func findByMsgId(_ msgId: Int64, _ sessionId: Int64) throws -> Message? {
        return try self.database?.getObject(
            on: Message.Properties.all,
            fromTable: self.tableName,
            where: Message.Properties.msgId == msgId && Message.Properties.sessionId == sessionId
        )
    }
    
    public func findById(_ id: Int64, _ fromUId: Int64, _ sessionId: Int64) throws -> Message? {
        return try self.database?.getObject(
            on: Message.Properties.all,
            fromTable: self.tableName,
            where: Message.Properties.id == id &&
            Message.Properties.fromUId == fromUId &&
            Message.Properties.sessionId == sessionId
        )
    }
    
    public func findOlderMessages(_ msgId: Int64, _ types: [Int], _ sessionId: Int64,  _ count: Int) throws -> [Message] {
        let msg = try self.findByMsgId(msgId, sessionId)
        guard let time = msg?.cTime else {
            return []
        }
        return self.findBySidAndTypesBeforeCTime(sessionId, msgId, types, time, count)
    }
    
    public func findNewerMessages(_ msgId: Int64, _ types: [Int], _ sessionId: Int64,  _ count: Int) throws -> [Message] {
        let msg = try self.findByMsgId(msgId, sessionId)
        guard let time = msg?.cTime else {
            return []
        }
        return self.queryBySidAndTypesAfterCTime(sessionId, msgId, types, time, count)
    }
    
    public func findByTimeRange(_ sessionId: Int64, _ startTime: Int64, _ endTime: Int64, _ count: Int, _ excludeMsgId: [Int64]) -> Array<Message> {
        let messages: Array<Message>? = try? self.database?.getObjects(
            fromTable: self.tableName,
            where: Message.Properties.sessionId == sessionId
            && !Message.Properties.msgId.in(excludeMsgId)
            && Message.Properties.cTime >= startTime
            && Message.Properties.cTime <= endTime
            && Message.Properties.type > 0,
            orderBy: [Message.Properties.cTime.order(Order.descending)],
            limit: count
        )
        if messages == nil {
            return Array<Message>()
        }
        
        var referMsgIds = [Int64]()
        for m in messages! {
            if m.referMsgId != nil {
                referMsgIds.append(m.referMsgId!)
            }
        }
        if !referMsgIds.isEmpty {
            let referMsgs: Array<Message>? = try? self.database?.getObjects(
                fromTable: self.tableName,
                where: Message.Properties.sessionId == sessionId &&
                Message.Properties.msgId.in(referMsgIds)
            )
            if referMsgs != nil {
                for referMsg in referMsgs! {
                    for m in messages! {
                        if m.referMsgId == referMsg.msgId {
                            m.referMsg = referMsg
                        }
                    }
                }
            }
            
        }
        return messages!
    }
    
    // 查询ctime之前的消息
    public func findBySidAndTypesBeforeCTime(_ sessionId: Int64, _ msgId: Int64, _ types: [Int], _ cTime: Int64, _ count: Int) -> Array<Message> {
        let message: Array<Message>? = try? self.database?.getObjects(
            fromTable: self.tableName,
            where: Message.Properties.sessionId == sessionId &&
            Message.Properties.msgId != msgId &&
            Message.Properties.cTime <= cTime &&
            Message.Properties.type.in(types),
            orderBy: [Message.Properties.cTime.order(Order.descending)],
            limit: count
        )
        return message ?? Array<Message>()
    }
    
    // 查询ctime之后的消息
    public func queryBySidAndTypesAfterCTime(_ sessionId: Int64, _ msgId: Int64, _ types: [Int], _ cTime: Int64, _ count: Int) -> Array<Message> {
        let message: Array<Message>? = try? self.database?.getObjects(
            fromTable: self.tableName,
            where: Message.Properties.sessionId == sessionId &&
            Message.Properties.msgId != msgId &&
            Message.Properties.cTime >= cTime &&
            Message.Properties.type.in(types),
            orderBy: [Message.Properties.cTime.order(Order.ascending)],
            limit: count
        )
        return message ?? Array<Message>()
    }
    
    public func findLastMessageBySessionId(_ sessionId: Int64) throws -> Message? {
        return try self.database?.getObject(
            fromTable: self.tableName,
            where: Message.Properties.sessionId == sessionId &&
            Message.Properties.type >= 0,
            orderBy: [Message.Properties.cTime.order(Order.descending)],
            offset: 0
        )
    }
    
    
    public func search(_ sessionId: Int64, _ type: Int, _ keyword: String, _ count: Int, _ offset: Int) -> Array<Message> {
        let message: Array<Message>? = try? self.database?.getObjects(
            fromTable: self.tableName,
            where: Message.Properties.sessionId == sessionId && Message.Properties.type == type && Message.Properties.content.like(keyword),
            orderBy: [Message.Properties.cTime.order(Order.descending)],
            limit: count,
            offset: offset
        )
        return message ?? Array<Message>()
    }
    
    public func search(_ sessionId: Int64, _ keyword: String, _ count: Int, _ offset: Int) -> Array<Message> {
        let message: Array<Message>? = try? self.database?.getObjects(
            fromTable: self.tableName,
            where: Message.Properties.sessionId == sessionId && Message.Properties.content.like(keyword),
            orderBy: [Message.Properties.cTime.order(Order.descending)],
            limit: count,
            offset: offset
        )
        return message ?? Array<Message>()
    }
    
    public func search(_ type: Int, _ keyword: String, _ count: Int, _ offset: Int) -> Array<Message> {
        let message: Array<Message>? = try? self.database?.getObjects(
            fromTable: self.tableName,
            where: Message.Properties.type == type && Message.Properties.content.like(keyword),
            orderBy: [Message.Properties.cTime.order(Order.descending)],
            limit: count,
            offset: offset
        )
        return message ?? Array<Message>()
    }
    
    public func search(_ keyword: String, _ count: Int, _ offset: Int) -> Array<Message> {
        let message: Array<Message>? = try? self.database?.getObjects(
            fromTable: self.tableName,
            where: Message.Properties.content.like(keyword),
            orderBy: [Message.Properties.cTime.order(Order.descending)],
            limit: count,
            offset: offset
        )
        return message ?? Array<Message>()
    }
    
    
}

