//
//  DefaultMessageDao.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/22.
//

import Foundation
import WCDBSwift
import CocoaLumberjack

class DefaultMessageDao : MessageDao {
    
    weak var database: Database?
    let tableName: String
    
    init(_ database: Database, _ tableName: String) {
        self.database = database
        self.tableName = tableName
    }
    
    func findMessageCountBySid(_ sessionId: Int64) throws -> Int64 {
        return try self.database!.getValue(
            on: Message.Properties.msgId.count(),
            fromTable: self.tableName,
            where: Message.Properties.sessionId == sessionId
        ).int64Value
    }
    
    
    func findMessageByMsgId(_ msgId: Int64, _ sessionId: Int64) throws -> Message? {
        return try self.database?.getObject(
            on: Message.Properties.all,
            fromTable: self.tableName,
            where: Message.Properties.msgId == msgId && Message.Properties.sessionId == sessionId
        )
    }
    
    func findMessageById(_ id: Int64, _ fromUId: Int64, _ sessionId: Int64) throws -> Message? {
        return try self.database?.getObject(
            on: Message.Properties.all,
            fromTable: self.tableName,
            where: Message.Properties.id == id &&
                Message.Properties.fromUId == fromUId &&
                Message.Properties.sessionId == sessionId
        )
    }
    
    func findOlderMessages(_ msgId: Int64, _ types: [Int], _ sessionId: Int64,  _ count: Int) throws -> [Message] {
        let msg = try self.findMessageByMsgId(msgId, sessionId)
        guard let time = msg?.cTime else {
            return []
        }
        return try self.queryMessageBySidAndBeforeCTime(sessionId, msgId, types, time, count) ?? []
    }
    
    func findNewerMessages(_ msgId: Int64, _ types: [Int], _ sessionId: Int64,  _ count: Int) throws -> [Message] {
        let msg = try self.findMessageByMsgId(msgId, sessionId)
        guard let time = msg?.cTime else {
            return []
        }
        return try self.queryMessageBySidAndAfterCTime(sessionId, msgId, types, time, count) ?? []
    }
    
    func insertOrReplaceMessages(_ messages: [Message]) throws {
        try self.database?.insertOrReplace(messages, intoTable: self.tableName)
    }
    
    func insertOrIgnoreMessages(_ messages: [Message]) throws {
        try self.database?.insertOrIgnore(messages, intoTable: self.tableName)
    }
    
    func updateMessages(_ messages: Message...) throws {
        for message in messages {
            try self.database?.update(
                table: self.tableName,
                on: Message.Properties.all,
                with: message,
                where: Message.Properties.id == message.id && Message.Properties.fromUId == message.fromUId
            )
        }
    }

    func updateMessageContent(_ sessionId: Int64, _ id: Int64, _ fromUId: Int64, _ content: String) throws {
        let update = StatementUpdate().update(table:self.tableName)
            .set(Message.Properties.operateStatus)
            .to(content)
            .where(
                Message.Properties.sessionId == sessionId
                   && Message.Properties.id == id
                   && Message.Properties.fromUId == fromUId
            )
        try self.database?.exec(update)
    }
    
    func updateMessageOperationStatus(_ sessionId: Int64, _ msgIds: [Int64], _ operateStatus: Int) throws {
        DDLogInfo("updateMessageOperationStatus \(msgIds) \(operateStatus)")
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
    func resetSendStatusFailed() throws {
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
    func getUnReadCount(_ sessionId: Int64) throws -> Int64 {
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
    
//    func getUnReadCountMessages(_ sessionId: Int64) throws -> [Message]? {
//        return try self.database?.getObjects(
//            on: Message.Properties.all,
//            fromTable: self.tableName,
//            where: Message.Properties.sessionId == sessionId &&
//                (Message.Properties.operateStatus & MsgOperateStatus.ClientRead.rawValue != 2)
//        )
//    }
    
    
    /**
     * 更新消息发送状态
     */
    func updateSendStatus(_ sessionId: Int64, _ id: Int64, _ fromUId: Int64, _ status: Int) throws {
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

    
    func deleteMessages(_ messages: Message...) throws {
        var ids = Array<Int64>()
        for message in messages {
            ids.append(message.id)
        }
        try self.database?.delete(fromTable: self.tableName, where: Message.Properties.id.in(ids))
    }
    
    func deleteMessages(_ messages: [Message]) throws {
        var ids = Array<Int64>()
        for message in messages {
            ids.append(message.id)
        }
        try self.database?.delete(fromTable: self.tableName, where: Message.Properties.id.in(ids))
    }
    
    func deleteMessagesByCTimeExclude(_ startTime: Int64, _ endTime: Int64) throws {
        try self.database?.delete(
            fromTable: self.tableName,
            where: Message.Properties.cTime < startTime || Message.Properties.cTime > endTime
        )
    }
    
    func deleteMessagesByCTimeInclude(_ startTime: Int64, _ endTime: Int64) throws {
        try self.database?.delete(
            fromTable: self.tableName,
            where: Message.Properties.cTime >= startTime && Message.Properties.cTime <= endTime
        )
    }
    
    /**
     * 删除session下的所有消息
     */
    func deleteSessionMessages(_ sessionId: Int64) throws {
        try self.database?.delete(
            fromTable: self.tableName,
            where: Message.Properties.sessionId == sessionId
        )
    }
    
    func queryMessageBySidAndCTime(_ sessionId: Int64, _ cTime: Int64, _ count: Int) throws -> Array<Message>? {
        return try self.database?.getObjects(
            fromTable: self.tableName,
            where: Message.Properties.sessionId == sessionId && Message.Properties.cTime < cTime && Message.Properties.type > 0,
            orderBy: [Message.Properties.cTime.order(Order.descending)],
            limit: count
        )
    }
    
    // 查询ctime之前的消息
    func queryMessageBySidAndBeforeCTime(_ sessionId: Int64, _ msgId: Int64, _ types: [Int], _ cTime: Int64, _ count: Int) throws -> Array<Message>? {
        return try self.database?.getObjects(
            fromTable: self.tableName,
            where: Message.Properties.sessionId == sessionId &&
                    Message.Properties.msgId != msgId &&
                    Message.Properties.cTime <= cTime &&
                    Message.Properties.type.in(types),
            orderBy: [Message.Properties.cTime.order(Order.descending)],
            limit: count
        )
    }
    
    // 查询ctime之后的消息
    func queryMessageBySidAndAfterCTime(_ sessionId: Int64, _ msgId: Int64, _ types: [Int], _ cTime: Int64, _ count: Int) throws -> Array<Message>? {
        return try self.database?.getObjects(
            fromTable: self.tableName,
            where: Message.Properties.sessionId == sessionId &&
                    Message.Properties.msgId != msgId &&
                    Message.Properties.cTime >= cTime &&
                    Message.Properties.type.in(types),
            orderBy: [Message.Properties.cTime.order(Order.ascending)],
            limit: count
        )
    }
    
    func findLastMessageBySessionId(_ sessionId: Int64) throws -> Message? {
        return try self.database?.getObject(
            fromTable: self.tableName,
            where: Message.Properties.sessionId == sessionId &&
                    Message.Properties.type >= 0,
            orderBy: [Message.Properties.cTime.order(Order.descending)],
            offset: 0
        )
    }
    
}

