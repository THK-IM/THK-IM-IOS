//
//  MessageModule.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/13.
//

import Foundation
import RxSwift

public protocol MessageModule : BaseModule {
    
    /**
     * 注册消息处理器
     */
    func registerMsgProcessor(_ processor: IMBaseMsgProcessor)
    
    /**
     * 获取注册消息处理器
     */
    func getMsgProcessor(_ msgType: Int) -> IMBaseMsgProcessor
    
    /**
     * 同步离线消息
     * @param count 每次同步消息数量
     */
    func syncOfflineMessages()
    
    /**
     * 同步最近session
     */
    func syncLatestSessionsFromServer()
    
    /**
     * 先查本地数据库后查服务端
     */
    func createSingleSession(_ entityId: Int64) -> Observable<Session>
    
    /**
     * 获取session, 先查本地数据库后查服务端
     */
    func getSession(_ sessionId: Int64) -> Observable<Session>
    
    /**
     * 分页获取本地session
     */
    func queryLocalSessions(_ parentId: Int64, _ count: Int, _ mTime: Int64) -> Observable<Array<Session>>
    
    /**
     * 分页获取本地message
     */
    func queryLocalMessages(_ sessionId: Int64, _ cTime: Int64, _ count: Int) -> Observable<Array<Message>>
    
    /**
     * 批量删除多条Session
     */
    func deleteSession(_ session: Session, _ deleteServer: Bool) -> Observable<Void>
    
    /**
     * 更新session
     */
    func updateSession(_ session: Session, _ updateSever: Bool) -> Observable<Void>
    
    /**
     * 收到新消息
     */
    func onNewMessage(_ msg: Message)
    
    /**
     * 生成新消息id
     */
    func generateNewMsgId() -> Int64
    
    /**
     * 发送消息
     */
    func sendMessage(_ sessionId: Int64, _ type: Int, _ body: Codable?, _ data: Codable?, _ atUser: String?,
                     _ replyMsgId: Int64?, _ sendResult: IMSendMsgResult?)
    
    /**
     * 消息发送到服务端
     */
    func sendMessageToServer(_ message: Message) -> Observable<Message>
    
    /**
     * 消息ack:需要ack的消息存入客户端缓存,批量按sessionId进行ack
     */
    func ackMessageToCache(_ msg: Message)
    
    /**
     * 消息ack:发送到服务端
     */
    func ackMessagesToServer()
    
    /**
     * 批量删除多条消息
     */
    func deleteMessages(_ sessionId: Int64, _ messages: Array<Message>, _ deleteServer: Bool) -> Observable<Void>
    
    
    /**
     * 处理session
     */
    func processSessionByMessage(_ msg: Message)
    
    
    /**
     * session下有新消息，发出提示音/震动等通知
     */
    func notifyNewMessage(_ session: Session, _ message: Message)
    
    
    /**
     * 取消所有执行中的任务
     */
    func cancelAllTasks()
    
}
