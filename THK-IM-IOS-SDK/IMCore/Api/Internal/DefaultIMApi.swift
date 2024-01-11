//
//  DefaultIMApi.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/22.
//

import Foundation
import Moya
import RxSwift

public class DefaultIMApi: IMApi {
    
    private let endpoint: String
    private var token: String
    private let apiInterceptor: APITokenInterceptor
    private let messageApi:MoyaProvider<IMMessageApi>
    private let sessionApi:MoyaProvider<IMSessionApi>
    private let userSessionApi:MoyaProvider<IMUserSessionApi>
    
    
    public init(token: String, endpoint: String) {
        self.endpoint = endpoint
        self.token = token
        self.apiInterceptor = APITokenInterceptor(token: token)
        self.apiInterceptor.addValidEndpoint(endpoint: endpoint)
        self.messageApi = MoyaProvider<IMMessageApi>(plugins: [self.apiInterceptor])
        self.sessionApi = MoyaProvider<IMSessionApi>(plugins: [self.apiInterceptor])
        self.userSessionApi = MoyaProvider<IMUserSessionApi>(plugins: [self.apiInterceptor])
    }
    
    public func getEndpoint() -> String {
        return self.endpoint
    }
    
    
    public func getToken() -> String {
        return self.token
    }
    
    public func updateToken(token: String) {
        self.token = token
        self.apiInterceptor.updateToken(token: token)
    }
    
    
    public func queryLatestSessionMembers(_ sessionId: Int64, _ mTime: Int64, _ role: Int?, _ count: Int) -> RxSwift.Observable<Array<SessionMember>> {
        return sessionApi.rx.request(.queryLatestSessionMembers(sessionId, mTime, role, count))
            .asObservable()
            .compose(RxTransformer.shared.response2Bean(ListVo<SessionMemberVo>.self))
            .flatMap({ listVo -> Observable<Array<SessionMember>> in
                var members = Array<SessionMember>()
                for vo in listVo.data {
                    members.append(vo.toSessionMember())
                }
                return Observable.just(members)
            })
        
    }
    
    
    
    public func queryUserLatestSessions(_ uId: Int64, _ count: Int, _ mTime: Int64, _ types: Set<Int>?) -> RxSwift.Observable<Array<Session>> {
        return userSessionApi.rx
            .request(.queryLatestSession(uId, 0, count, mTime, types))
            .asObservable()
            .compose(RxTransformer.shared.response2Bean(ListVo<SessionVo>.self))
            .flatMap({ (sessionListVo) -> Observable<Array<Session>> in
                var array = [Session]()
                for vo in sessionListVo.data {
                    let s = vo.toSession()
                    array.append(s)
                }
                return Observable.just(array)
            })
    }
    
    public func queryUserSession(_ uId: Int64, _ sessionId: Int64) -> Observable<Session> {
        return userSessionApi.rx
            .request(.querySession(uId, sessionId))
            .asObservable()
            .compose(RxTransformer.shared.response2Bean(SessionVo.self))
            .flatMap({ (vo) -> Observable<Session> in
                let session = vo.toSession()
                return Observable.just(session)
            })
    }
    
    
    
    /**
     * 获取与用户的session
     */
    public func queryUserSession(_ uId: Int64, _ entityId: Int64, _ type: Int) -> Observable<Session> {
        return userSessionApi.rx
            .request(.querySessionByEntityId(uId, entityId, type))
            .asObservable()
            .compose(RxTransformer.shared.response2Bean(SessionVo.self))
            .flatMap({ (vo) -> Observable<Session> in
                let session = vo.toSession()
                return Observable.just(session)
            })
    }
    
    public func deleteUserSession(_ uId: Int64, session: Session)-> Observable<Void> {
        return userSessionApi.rx
            .request(.deleteSession(uId, session.id))
            .asObservable()
            .compose(RxTransformer.shared.response2Void())
    }

    public func updateUserSession(_ uId: Int64, session: Session)-> Observable<Void> {
        let req = UpdateSessionVo(uId: uId, sId: session.id, top: session.topTimestamp, status: session.status, parentId: session.parentId)
        return userSessionApi.rx
            .request(.updateSession(req))
            .asObservable()
            .compose(RxTransformer.shared.response2Void())
    }
    
    public func sendMessageToServer(msg: Message) -> Observable<Message> {
        let req = MessageVo(msg: msg)
        return messageApi.rx
            .request(.sendMsg(req))
            .asObservable()
            .compose(RxTransformer.shared.response2Bean(MessageVo.self))
            .flatMap({ (bean) -> Observable<Message> in
                msg.msgId = bean.msgId
                msg.cTime = bean.cTime
                msg.sendStatus = MsgSendStatus.Success.rawValue
                msg.operateStatus = MsgOperateStatus.Ack.rawValue
                            | MsgOperateStatus.ClientRead.rawValue
                            | MsgOperateStatus.ServerRead.rawValue
                return Observable.just(msg)
            })
    }
    
    public func ackMessages(_ uId: Int64, _ sessionId: Int64, _ msgIds: Set<Int64>) -> Observable<Void> {
        let req = AckMsgVo(sessionId: sessionId, uId: uId, msgIds: msgIds)
        return messageApi.rx
            .request(.ackMsgs(req))
            .asObservable()
            .compose(RxTransformer.shared.response2Void())
    }
    
    public func readMessages(_ uId: Int64, _ sessionId: Int64, _ msgIds: Set<Int64>) -> Observable<Void> {
        let req = ReadMsgVo(sessionId: sessionId, uId: uId, msgIds: msgIds)
        return messageApi.rx
            .request(.readMsgs(req))
            .asObservable()
            .compose(RxTransformer.shared.response2Void())
    }
    
    public func revokeMessage(_ uId: Int64, _ sessionId: Int64, _ msgId: Int64) -> Observable<Void> {
        let req = RevokeMsgVo(sessionId: sessionId, uId: uId, msgId: msgId)
        return messageApi.rx
            .request(.revokeMsg(req))
            .asObservable()
            .compose(RxTransformer.shared.response2Void())
    }
    
    public func reeditMessage(_ uId: Int64, _ sessionId: Int64, _ msgId: Int64, _ body: String) -> Observable<Void> {
        var msgIds = Set<Int64>()
        msgIds.insert(msgId)
        let req = AckMsgVo(sessionId: sessionId, uId: uId, msgIds: msgIds)
        return messageApi.rx
            .request(.ackMsgs(req))
            .asObservable()
            .compose(RxTransformer.shared.response2Void())
    }
    
    
    public func forwardMessages(_ msg: Message, forwardSid: Int64, fromUserIds: Set<Int64>, clientMsgIds: Set<Int64>) -> Observable<Message> {
        let req = ForwardMessageVo(msg: msg, forwardSid: forwardSid, forwardFromUIds: fromUserIds, forwardClientIds: clientMsgIds)
        return messageApi.rx
            .request(.forwardMsg(req))
            .asObservable()
            .compose(RxTransformer.shared.response2Bean(ForwardMessageVo.self))
            .flatMap({ (vo) -> Observable<Message> in
                msg.msgId = vo.msgId
                msg.cTime = vo.cTime
                msg.sendStatus = MsgSendStatus.Success.rawValue
                msg.operateStatus = MsgOperateStatus.Ack.rawValue
                            | MsgOperateStatus.ClientRead.rawValue
                            | MsgOperateStatus.ServerRead.rawValue
                return Observable.just(msg)
            })
    }
    
    public func deleteMessages(_ uId: Int64, _ sessionId: Int64, _ msgIds: Set<Int64>) -> Observable<Void> {
        let req = DeleteMsgVo(sessionId: sessionId, uId: uId, msgIds: msgIds)
        return messageApi.rx
            .request(.deleteMsgs(req))
            .asObservable()
            .compose(RxTransformer.shared.response2Void())
    }
    
    public func getLatestMessages(_ uId: Int64, _ cTime: Int64, _ count: Int) -> Observable<Array<Message>> {
        return messageApi.rx
            .request(.queryLatestMsg(uId, 0, count, cTime))
            .asObservable()
            .compose(RxTransformer.shared.response2Bean(ListVo<MessageVo>.self))
            .flatMap({ (messageListVo) -> Observable<Array<Message>> in
                var array = [Message]()
                for vo in messageListVo.data {
                    let s = vo.toMessage()
                    array.append(s)
                }
                return Observable.just(array)
            })
    }
    
    
}
