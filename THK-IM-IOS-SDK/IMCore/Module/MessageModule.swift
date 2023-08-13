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
     * 新消息id
     */
    func newMsgId() -> Int64
    
    /**
     * 消息ack,需要ack的消息存入客户端缓存
     */
    func ackMessage(_ sId: Int64, _ msgId: Int64)
    
    
    /**
     * 客户端发起消息ack
     */
    func ackMessages()
    
    /**
     * 服务端消息ack
     */
    func ackServerMessage(_ sId: Int64, _ msgIds: Set<Int64>)
    
    /**
     * 删除服务端消息
     */
    func deleteServerMessages(_ sId: Int64, _ msgIds: Array<Int64>) -> Observable<ErrorBean>
    
    /**
     * 【用户主动发起】批量删除多条消息
     */
    func deleteMessages(_ sId: Int64, _ messages: Array<Message>, _ deleteServer: Bool) -> Observable<Bool>
    
    /**
     * 【收到服务器通知】 收到新消息
     */
    func onNewMessage(_ bean: MessageBean)
    
    /**
     * 【用户主动发起】发送新消息
     */
    func sendMessage(_ sId: Int64, _ type: Int, _ msgBody: String)
    
    /**
     * 【用户主动发起】重发消息
     */
    func resendMessage(_ message: Message)
    
    /**
     * 调用api发送消息到服务器
     */
    func sendMessageToServer(_ bean: MessageBean) -> Observable<MessageBean>
    
    /**
     * 【用户主动发起】 同步最近消息
     */
    func syncLatestMessagesFromServer(
        _ cTime: Int64,
        _ offset: Int,
        _ size: Int
    ) -> Observable<Array<MessageBean>>
    
    /**
     * 【系统连接成功后发起】
     */
    func syncOfflineMessages(_ time: Int64, _ offset: Int, _ size: Int)
    
    /**
     * 【用户主动发起】 同步所有消息
     */
    func syncAllMessages(_ offset: Int, _ size: Int)
    
    /**
     * 【用户主动发起】同步最近session
     */
    func syncLatestSessionsFromServer(_ offset: Int, _ size: Int) -> Observable<Array<SessionBean>>
    
    /**
     * 【用户主动发起】获取与某个用户的session
     */
    func getSession(
        _ uId: Int64,
        _ map: Dictionary<String, Any>?
    ) -> Observable<Session>
    
    /**
     * 【用户主动发起】查询/创建服务器session
     */
    func getSessionFromServerByEntityId(
        _ entityId: Int64,
        _ type: Int,
        _ map: Dictionary<String, Any>?
    ) -> Observable<SessionBean>
    
    /**
     * 【用户主动发起】查询session
     */
    func querySessionFromServer(_ sId: Int64) -> Observable<SessionBean>
    
    
    /**
     * 【用户主动发起】查询session
     */
    func queryLocalSession(_ sId: Int64) -> Observable<Session>
    
    
    /**
     * 【用户主动发起】查询session
     */
    func querySession(_ sId: Int64) -> Observable<Session>
    
    /**
     * 【用户主动发起】同步所有session
     */
    func syncAllSessionsFromServer(_ offset: Int, _ size: Int) -> Observable<Array<SessionBean>>
    
    
    /**
     * 【用户主动发起】分页获取本地session
     */
    func queryLocalSessions(_ size: Int, _ mTime: Int64) -> Observable<Array<Session>>
    
    /**
     * 【用户主动发起】分页获取本地message
     */
    func queryLocalMessages(_ sId: Int64, _ cTime: Int64, _ size: Int) -> Observable<Array<Message>>
    
    
    /**
     * 删除服务端会话
     */
    func deleteServerSession(_ sessionList: Array<Session>) -> Observable<Int>
    
    
    /**
     * 删除本地会话
     */
    func deleteLocalSession(_ sessionList: Array<Session>) -> Observable<Int>
    
    
    /**
     * 【用户主动发起】批量删除多条Session
     */
    func deleteSession(_ sessionList: Array<Session>, _ deleteServer: Bool) -> Observable<Bool>
    
    
    /**
     * 标记session对应的所有消息为已读
     */
    func signMessageReadBySessionId(_ sId: Int64)
    
    
    /**
     * 收到新消息后session处理
     */
    func processSessionByMessage(_ msg: Message)
    
    /**
     * 注册消息处理器
     */
    func registerMsgProcessor(_ processor: BaseMsgProcessor)
    
    
    /**
     * 注册消息处理器
     */
    func getMsgProcessor(_ msgType: Int) -> BaseMsgProcessor
    
    /**
     * 设置离线消息同步时间
     */
    func setOfflineMsgSyncTime(_ time: Int64) -> Bool
    
    /**
     * 获取离线消息上次同步时间
     */
    func getOfflineMsgLastSyncTime() -> Int64
    
}
