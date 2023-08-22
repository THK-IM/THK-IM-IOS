//
//  MessageModule.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/13.
//

import Foundation
import RxSwift

protocol MessageModule : BaseModule {
    
    /**
     * 注册消息处理器
     */
    func registerMsgProcessor(_ processor: BaseMsgProcessor)
    
    /**
     * 获取注册消息处理器
     */
    func getMsgProcessor(_ msgType: Int) -> BaseMsgProcessor
    
    /**
     * 同步离线消息
     * @param count 每次同步消息数量
     */
    func syncOfflineMessages()
    
    /**
     * 同步最近session
     */
    func syncLatestSessionsFromServer(_ lastSyncTime: Int, _ count: Int)
    
    /**
     * 创建entityId和sessionType对应的session, 先查本地数据库后查服务端
     */
    func createSession(_ entityId: Int64, _ sessionType: Int) -> Observable<Session>
    
    /**
     * 获取session, 先查本地数据库后查服务端
     */
    func getSession(_ sessionId: Int64) -> Observable<Session>
    
    /**
     * 分页获取本地session
     */
    func queryLocalSessions(_ count: Int, _ mTime: Int64) -> Observable<Array<Session>>
    
    /**
     * 分页获取本地message
     */
    func queryLocalMessages(_ sessionId: Int64, _ cTime: Int64, _ count: Int) -> Observable<Array<Message>>
    
    /**
     * 批量删除多条Session
     */
    func deleteSession(_ sessionList: Array<Session>, _ deleteServer: Bool) -> Observable<Bool>
    
    /**
     * 收到新消息
     */
    func onNewMessage(_ msg: Message)
    
    /**
     * 生成新消息id
     */
    func generateNewMsgId() -> Int64
    
    /**
     * 消息发送到服务端
     */
    func sendMessageToServer(_ message: Message) -> Observable<Message>
    
    /**
     * 标记消息已读
     */
    func readMessages(_ sessionId: Int64, _ msgIds: [Int64]?) -> Observable<Bool>
    
    /**
     * 撤回消息
     */
    func revokeMessage(_ message: Message) -> Observable<Bool>
    
    
    /**
     * 重新编辑消息
     */
    func reeditMessage(_ message: Message) -> Observable<Bool>
    
    /**
     * 消息ack:需要ack的消息存入客户端缓存,批量按sessionId进行ack
     */
    func ackMessageToCache(_ sessionId: Int64, _ msgId: Int64)
    
    /**
     * 消息ack:发送到服务端
     */
    func ackMessagesToServer()
    
    /**
     * 批量删除多条消息
     */
    func deleteMessages(_ sessionId: Int64, _ messages: Array<Message>, _ deleteServer: Bool) -> Observable<Bool>
    
    
    /**
     * 处理session
     */
    func processSessionByMessage(_ msg: Message)
    
}
