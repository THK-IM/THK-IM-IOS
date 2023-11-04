//
//  DefaultIMApi.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/22.
//

import Foundation
import Moya
import RxSwift

class DefaultIMApi: IMApi {
    
    private let messageApi = MoyaProvider<IMMessageApi>(plugins: [NetworkLoggerPlugin()])
    private let sessionApi = MoyaProvider<IMSessionApi>(plugins: [NetworkLoggerPlugin()])
    
    private let _endpoint: String
    
    init(endpoint: String) {
        self._endpoint = endpoint
    }
    
    func endpoint() -> String {
        return self._endpoint
    }
    
    func getLatestModifiedSessions(_ uId: Int64, _ count: Int, _ mTime: Int64) -> Observable<Array<Session>> {
        return sessionApi.rx
            .request(.queryLatestSession(uId, 0, count, mTime))
            .asObservable()
            .compose(RxTransformer.shared.response2Bean(ListBean<SessionBean>.self))
            .flatMap({ (sessionListBean) -> Observable<Array<Session>> in
                var array = [Session]()
                for bean in sessionListBean.data {
                    let s = bean.toSession()
                    array.append(s)
                }
                return Observable.just(array)
            })
    }
    
    func querySession(_ uId: Int64, _ sessionId: Int64) -> Observable<Session> {
        return sessionApi.rx
            .request(.querySession(uId, sessionId))
            .asObservable()
            .compose(RxTransformer.shared.response2Bean(SessionBean.self))
            .flatMap({ (sessionBean) -> Observable<Session> in
                let session = sessionBean.toSession()
                return Observable.just(session)
            })
    }
    
    func createSession(_ uId: Int64, _ sessionType: Int, _ entityId: Int64, _ members: Set<Int64>?) -> Observable<Session> {
        let reqBean = CreateSessionBean(uId: uId, type: sessionType, entityId: entityId, members: members)
        return sessionApi.rx
            .request(.createSession(reqBean))
            .asObservable()
            .compose(RxTransformer.shared.response2Bean(SessionBean.self))
            .flatMap({ (bean) -> Observable<Session> in
                let session = bean.toSession()
                return Observable.just(session)
            })
    }
    
    func sendMessageToServer(msg: Message) -> Observable<Message> {
        let reqBean = MessageBean(msg: msg)
        return messageApi.rx
            .request(.sendMsg(reqBean))
            .asObservable()
            .compose(RxTransformer.shared.response2Bean(MessageBean.self))
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
    
    func ackMessages(_ uId: Int64, _ sessionId: Int64, _ msgIds: Set<Int64>) -> Observable<Void> {
        let reqBean = AckMsgBean(sessionId: sessionId, uId: uId, msgIds: msgIds)
        return messageApi.rx
            .request(.ackMsgs(reqBean))
            .asObservable()
            .compose(RxTransformer.shared.response2Void())
    }
    
    func readMessages(_ uId: Int64, _ sessionId: Int64, _ msgIds: Set<Int64>) -> Observable<Void> {
        let reqBean = ReadMsgBean(sessionId: sessionId, uId: uId, msgIds: msgIds)
        return messageApi.rx
            .request(.readMsgs(reqBean))
            .asObservable()
            .compose(RxTransformer.shared.response2Void())
    }
    
    func revokeMessage(_ uId: Int64, _ sessionId: Int64, _ msgId: Int64) -> Observable<Void> {
        var msgIds = Set<Int64>()
        msgIds.insert(msgId)
        let reqBean = AckMsgBean(sessionId: sessionId, uId: uId, msgIds: msgIds)
        return messageApi.rx
            .request(.ackMsgs(reqBean))
            .asObservable()
            .compose(RxTransformer.shared.response2Void())
    }
    
    func reeditMessage(_ uId: Int64, _ sessionId: Int64, _ msgId: Int64, _ body: String) -> Observable<Void> {
        var msgIds = Set<Int64>()
        msgIds.insert(msgId)
        let reqBean = AckMsgBean(sessionId: sessionId, uId: uId, msgIds: msgIds)
        return messageApi.rx
            .request(.ackMsgs(reqBean))
            .asObservable()
            .compose(RxTransformer.shared.response2Void())
    }
    
    func deleteMessages(_ uId: Int64, _ sessionId: Int64, _ msgIds: Set<Int64>) -> Observable<Void> {
        let reqBean = DeleteMsgBean(sessionId: sessionId, uId: uId, msgIds: msgIds)
        return messageApi.rx
            .request(.deleteMsgs(reqBean))
            .asObservable()
            .compose(RxTransformer.shared.response2Void())
    }
    
    func getLatestMessages(_ uId: Int64, _ cTime: Int64, _ count: Int) -> Observable<Array<Message>> {
        return messageApi.rx
            .request(.queryLatestMsg(uId, 0, count, cTime))
            .asObservable()
            .compose(RxTransformer.shared.response2Bean(ListBean<MessageBean>.self))
            .flatMap({ (messageListBean) -> Observable<Array<Message>> in
                var array = [Message]()
                for bean in messageListBean.data {
                    let s = bean.toMessage()
                    array.append(s)
                }
                return Observable.just(array)
            })
    }
    
    
}
