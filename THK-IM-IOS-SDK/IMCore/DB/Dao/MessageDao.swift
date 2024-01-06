//
//  MessageDao.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/14.
//

import Foundation

public protocol MessageDao {
    
    /**
     * 批量插入消息
     */
    func insertOrReplace(_ messages: [Message]) throws
    
    /**
     * 插入消息
     */
    func insertOrIgnore(_ messages: [Message]) throws
    
    /**
     * 删除消息
     */
    func delete(_ messages: Message...) throws
    
    /**
     * 批量删除消息
     */
    func delete(_ messages: [Message]) throws
    
    /**
     * 删除时间段以外消息
     */
    func deleteByCTimeExclude(_ startTime: Int64, _ endTime: Int64) throws
    
    /**
     * 删除时间段以内消息
     */
    func deleteByIncludeCTime(_ startTime: Int64, _ endTime: Int64) throws
    
    /**
     * 删除session下的所有消息
     */
    func deleteBySessionId(_ sessionId: Int64) throws
    
    
    /**
     * 批量更新消息
     */
    func update(_ messages: Message...) throws
    
   
    /**
     * 更新消息内容
     */
    func updateContent(_ sessionId: Int64, _ id: Int64, _ fromUId: Int64, _ content: String) throws
    
    /**
     * 更新消息操作状态
     */
    func updateOperationStatus(_ sessionId: Int64, _ msgIds: [Int64], _ operateStatus: Int) throws
    
    /**
     * 重置消息发送状态为失败
     */
    func resetSendStatusFailed() throws
    
    /**
     * 更新消息发送状态
     */
    func updateSendStatus(_ sessionId: Int64, _ id: Int64, _ fromUserId: Int64, _ status: Int) throws
    
    /**
     * 获取session下的未读数
     */
    func getUnReadCount(_ sessionId: Int64) throws -> Int64
    
    /**
     * 根据sessionId查询消息数
     */
    func findSessionMessageCount(_ sessionId: Int64) throws -> Int64
    
    /**
     * 根据msgId和sessionId查询消息
     */
    func findByMsgId(_ msgId: Int64, _ sessionId: Int64) throws -> Message?
    
    /**
     * 根据id、fromUId、sessionId查询消息
     */
    func findById(_ id: Int64, _ fromUId: Int64,  _ sessionId: Int64) throws -> Message?
    
    /**
     * 查询比msgId早的消息
     */
    func findOlderMessages(_ msgId: Int64, _ types: [Int], _ sessionId: Int64,  _ count: Int) throws -> [Message]
    
    /**
     * 查询比msgId晚的消息
     */
    func findNewerMessages(_ msgId: Int64, _ types: [Int], _ sessionId: Int64,  _ count: Int) throws -> [Message]
    
    /**
     * 查询session下某时间之后的消息
     */
    func findBySidAfterCTime(_ sessionId: Int64, _ cTime: Int64, _ count: Int) throws -> Array<Message>?
    
    /**
     * 查询session下某时间之前的消息
     */
    func findBySidAndTypesBeforeCTime(_ sessionId: Int64, _ msgId: Int64, _ types: [Int], _ cTime: Int64, _ count: Int) throws -> Array<Message>?
    
    /**
     * 查询ctime之后的消息
     */
    func queryBySidAndTypesAfterCTime(_ sessionId: Int64,  _ msgId: Int64, _ types: [Int], _ cTime: Int64, _ count: Int) throws -> Array<Message>?
    
    /**
     * 查询session的最后一条消息
     */
    func findLastMessageBySessionId(_ sessionId: Int64) throws -> Message?
    
}
