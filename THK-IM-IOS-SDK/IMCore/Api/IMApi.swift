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
     * 根据修改时间查询session成员
     */
    func queryLatestSessionMembers(_ sessionId: Int64, _ mTime: Int64, _ role: Int?, _ count: Int)
        -> Observable<[SessionMember]>

    /**
     * 获取修改时间为mTime之后的session列表
     */
    func queryUserLatestSessions(_ uId: Int64, _ count: Int, _ mTime: Int64) -> Observable<
        [Session]
    >

    /**
     * 获取与用户的session
     */
    func queryUserSession(_ uId: Int64, _ sessionId: Int64) -> Observable<Session>

    /**
     * 获取与用户的session
     */
    func queryUserSession(_ uId: Int64, _ entityId: Int64, _ type: Int) -> Observable<Session>

    /**
     * 删除用户session
     */
    func deleteUserSession(_ uId: Int64, session: Session) -> Observable<Void>

    /**
     * 根新用户session
     */
    func updateUserSession(_ uId: Int64, session: Session) -> Observable<Void>

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
    func reeditMessage(_ uId: Int64, _ sessionId: Int64, _ msgId: Int64, _ body: String)
        -> Observable<Void>

    /**
     * 转发消息
     */
    func forwardMessages(
        _ msg: Message, forwardSid: Int64, fromUserIds: Set<Int64>, clientMsgIds: Set<Int64>
    ) -> Observable<Message>

    /**
     * 删除消息
     */
    func deleteMessages(_ uId: Int64, _ sessionId: Int64, _ msgIds: Set<Int64>) -> Observable<Void>

    /**
     * 获取cTime之后创建的消息
     */
    func getLatestMessages(_ uId: Int64, _ cTime: Int64, _ count: Int) -> Observable<[Message]>

    /**
     * 获取cTime之前的session消息
     */
    func querySessionMessages(sId: Int64, cTime: Int64, offset: Int, count: Int, asc: Int)
        -> Observable<[Message]>

}
