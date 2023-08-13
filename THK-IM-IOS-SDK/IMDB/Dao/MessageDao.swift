//
//  MessageDao.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/14.
//

import Foundation
import WCDBSwift

protocol MessageDao {
    
    func findMessageCountBySid(_ sessionId: Int64) throws -> Int64
    
    func findMessageBySid(_ msgId: Int64, _ sessionId: Int64) throws -> Message?
    
    func findMessage(_ id: Int64, _ fUId: Int64) throws -> Message?
    
    func findOlderMessages(_ msgId: Int64, _ types: [Int], _ sessionId: Int64,  _ count: Int) throws -> [Message]?
    
    func findNewerMessages(_ msgId: Int64, _ types: [Int], _ sessionId: Int64,  _ count: Int) throws -> [Message]?
    
    func insertMessages(_ messages: [Message]) throws
    
    func insertMessages(_ messages: Message...) throws
    
    func updateMessages(_ messages: Message...) throws
    
    func updateMessageContent(_ id: Int64,  _ fUId: Int64, _ content: String) throws
    
    func ackSessionMessages(sid: Int64, msgIds: [Int64]) throws
    
    func readSessionMessages(sid: Int64, msgIds: [Int64]) throws
    
    func updateMessageStatus(_ id: Int64,  _ fUId: Int64, _ status: Int, _ msgId: Int64, _ time: Int64) throws
    
    func deleteMessages(_ messages: Message...) throws
    
    func deleteMessages(_ messages: [Message]) throws
    
    func deleteMessagesByCTimeExclude(_ startTime: Int64, _ endTime: Int64) throws
    
    func deleteMessagesByCTimeInclude(_ startTime: Int64, _ endTime: Int64) throws
    
    func queryMessageBySidAndCTime(_ sid: Int64, _ cTime: Int64, _ count: Int) throws -> Array<Message>?
    
    // 查询ctime之前的消息
    func queryMessageBySidAndBeforeCTime(_ sid: Int64, _ types: [Int], _ cTime: Int64, _ count: Int) throws -> Array<Message>?
    
    // 查询ctime之后的消息
    func queryMessageBySidAndAfterCTime(_ sid: Int64, _ types: [Int], _ cTime: Int64, _ count: Int) throws -> Array<Message>?
    
    func resetSendingMsg(_ status: Int) throws
}

class innerMessageDao : MessageDao {
    
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
            where: Message.Properties.sid == sessionId
        ).int64Value
    }
    
    func findMessageBySid(_ msgId: Int64, _ sessionId: Int64) throws -> Message? {
        return try self.database?.getObject(
            on: Message.Properties.all,
            fromTable: self.tableName,
            where: Message.Properties.msgId == msgId && Message.Properties.sid == sessionId
        )
    }
    
    func findMessage(_ id: Int64, _ fUId: Int64) throws  -> Message?  {
        return try self.database?.getObject(
            on: Message.Properties.all,
            fromTable: self.tableName,
            where: Message.Properties.id == id && Message.Properties.fUId == fUId
        )
    }
    
    func findOlderMessages(_ msgId: Int64, _ types: [Int], _ sessionId: Int64,  _ count: Int) throws -> [Message]? {
        let msg = try self.findMessageBySid(msgId, sessionId)
        guard let time = msg?.cTime else {
            return []
        }
        return try self.queryMessageBySidAndBeforeCTime(sessionId, types, time, count)
    }
    
    func findNewerMessages(_ msgId: Int64, _ types: [Int], _ sessionId: Int64,  _ count: Int) throws -> [Message]? {
        let msg = try self.findMessageBySid(msgId, sessionId)
        guard let time = msg?.cTime else {
            return []
        }
        return try self.queryMessageBySidAndAfterCTime(sessionId, types, time, count)
    }
    
    func insertMessages(_ messages: [Message]) throws {
        try self.database?.insertOrIgnore(messages, intoTable: self.tableName)
    }
    
    
    func insertMessages(_ messages: Message...) throws {
        try self.database?.insertOrIgnore(messages, intoTable: self.tableName)
    }
    
    func updateMessages(_ messages: Message...) throws {
        for message in messages {
            try self.database?.update(
                table: self.tableName,
                on: Message.Properties.all,
                with: message,
                where: Message.Properties.id == message.id && Message.Properties.fUId == message.fUId
            )
        }
    }
    
    func updateMessageContent(_ id: Int64, _ fUId: Int64, _ content: String) throws {
        let msg = Message()
        msg.content = content
        try self.database?.update(
            table: self.tableName,
            on: Message.Properties.content,
            with: msg,
            where: Message.Properties.id == id && Message.Properties.fUId == fUId
        )
    }
    
    func ackSessionMessages(sid: Int64, msgIds: [Int64]) throws {
        try self.updateMessagesStatus(status: 1, sid: sid, msgIds: msgIds)
    }
    
    func readSessionMessages(sid: Int64, msgIds: [Int64]) throws {
        try self.updateMessagesStatus(status: 2, sid: sid, msgIds: msgIds)
    }
    
    private func updateMessagesStatus(status: Int, sid: Int64, msgIds: [Int64]) throws {
        let statusColumn = Column(named: "status")
        let expression1 = Expression(with: statusColumn)
        let expression2 = Expression(with: status)
        let expression3 = expression1 | expression2
        
        let update = StatementUpdate().update(table:self.tableName)
            .set(Message.Properties.status)
            .to(expression3)
            .where(Message.Properties.sid == sid
                   && Message.Properties.msgId.in(msgIds)
            )
        try self.database?.exec(update)
    }
    
    func updateMessageStatus(_ id: Int64, _ fUId: Int64, _ status: Int, _ msgId: Int64, _ time: Int64) throws {
        let msg = Message()
        msg.status = status
        msg.msgId = msgId
        msg.cTime = time
        msg.mTime = time
        try self.database?.update(
            table: self.tableName,
            on: [Message.Properties.status, Message.Properties.msgId, Message.Properties.cTime, Message.Properties.mTime],
            with: msg,
            where: Message.Properties.id == id && Message.Properties.fUId == fUId
        )
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
    
    func queryMessageBySidAndCTime(_ sid: Int64, _ cTime: Int64, _ count: Int) throws -> Array<Message>? {
        return try self.database?.getObjects(
            fromTable: self.tableName,
            where: Message.Properties.sid == sid && Message.Properties.cTime < cTime,
            orderBy: [Message.Properties.cTime.order(Order.descending)],
            limit: count
        )
    }
    
    // 查询ctime之前的消息
    func queryMessageBySidAndBeforeCTime(_ sid: Int64, _ types: [Int], _ cTime: Int64, _ count: Int) throws -> Array<Message>? {
        return try self.database?.getObjects(
            fromTable: self.tableName,
            where: Message.Properties.sid == sid &&
                    Message.Properties.cTime < cTime &&
                    Message.Properties.type.in(types),
            orderBy: [Message.Properties.cTime.order(Order.descending)],
            limit: count
        )
    }
    
    // 查询ctime之后的消息
    func queryMessageBySidAndAfterCTime(_ sid: Int64, _ types: [Int], _ cTime: Int64, _ count: Int) throws -> Array<Message>? {
        return try self.database?.getObjects(
            fromTable: self.tableName,
            where: Message.Properties.sid == sid &&
                    Message.Properties.cTime > cTime &&
                    Message.Properties.type.in(types),
            orderBy: [Message.Properties.cTime.order(Order.ascending)],
            limit: count
        )
    }
    
    
    func resetSendingMsg(_ status: Int) throws {
        let msg = Message()
        msg.status = status
        try self.database?.update(
            table: self.tableName,
            on: [Message.Properties.status],
            with: msg,
            where: Message.Properties.status == MsgStatus.Sending.rawValue || Message.Properties.status == MsgStatus.Init.rawValue)
    }
    
}
