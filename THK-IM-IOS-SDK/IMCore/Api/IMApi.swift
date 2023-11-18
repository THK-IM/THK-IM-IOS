//
//  IMApi.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/22.
//

import Foundation
import RxSwift

public protocol IMApi: AnyObject {
    
    /**
     * token
     */
    func getToken() -> String
    
    /**
     * api地址
     */
    func getEndpoint() -> String
    
    /**
     * 获取修改时间为mTime之后的session列表
     */
    func getLatestModifiedSessions(_ uId: Int64, _ count: Int, _ mTime: Int64) -> Observable<Array<Session>>
    
    /**
     * 获取与用户的session
     */
    func querySession(_ uId: Int64, _ sessionId: Int64) -> Observable<Session>
    
    /**
     * 创建会话
     */
    func createSession(_ uId: Int64, _ sessionType: Int, _ entityId: Int64, _ members: Set<Int64>?) -> Observable<Session>
    
    
    /**
     * 删除用户session
     */
    func deleteSession(_ uId: Int64, session: Session)-> Observable<Void>

    /**
     * 根新用户session
     */
    func updateSession(_ uId: Int64, session: Session)-> Observable<Void>
    
    /**
     * 发送消息到服务端
     */
    func sendMessageToServer(msg: Message) -> Observable<Message>
    
    /**
     * 消息设置ack
     */
    func ackMessages(_ uId: Int64, _ sessionId: Int64, _ msgIds: Set<Int64>) -> Observable<Void>
    
    /**
     * 消息设置已读
     */
    func readMessages(_ uId: Int64, _ sessionId: Int64, _ msgIds: Set<Int64>) -> Observable<Void>
    
    /**
     * 撤回消息
     */
    func revokeMessage(_ uId: Int64, _ sessionId: Int64, _ msgId: Int64) -> Observable<Void>
    
    /**
     * 重新编辑消息
     */
    func reeditMessage(_ uId: Int64, _ sessionId: Int64, _ msgId: Int64, _ body: String) -> Observable<Void>
    
    /**
     * 删除消息
     */
    func deleteMessages(_ uId: Int64, _ sessionId: Int64, _ msgIds: Set<Int64>) -> Observable<Void>
    
    /**
     * 获取cTime之后创建的消息
     */
    func getLatestMessages(_ uId: Int64, _ cTime: Int64, _ count: Int) -> Observable<Array<Message>>
    
}

