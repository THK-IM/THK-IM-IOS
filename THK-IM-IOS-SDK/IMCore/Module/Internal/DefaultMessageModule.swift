//
//  DefaultMessageModule.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/18.
//

import Foundation
import Moya
import RxSwift
import SwiftEventBus
import CocoaLumberjack

open class DefaultMessageModule : MessageModule {
    
    private let messageApi = MoyaProvider<IMMessageApi>(plugins: [NetworkLoggerPlugin()])
    private let sessionApi = MoyaProvider<IMSessionApi>(plugins: [NetworkLoggerPlugin()])
    private var processorDic = [Int: BaseMsgProcessor]()
    private let disposeBag = DisposeBag()
    private var lastTimestamp : Int64 = 0
    private var lastSequence : Int = 0
    private var needAckDic = [Int64: Set<Int64>]()
    private let idLock = NSLock()
    private let ackLock = NSLock()
    private let msgLock = NSLock()
    
    func registerMsgProcessor(_ processor: BaseMsgProcessor) {
        processorDic[processor.messageType()] = processor
    }
    
    func getMsgProcessor(_ msgType: Int) -> BaseMsgProcessor {
        let processor = processorDic[msgType]
        return (processor != nil) ? (processor!) : processorDic[0]!
    }
    
    func newMsgId() -> Int64 {
        idLock.lock()
        defer {
            idLock.unlock()
        }
        let current = IMManager.shared.severTime
        if (current == self.lastTimestamp) {
            self.lastSequence += 1
        } else {
            self.lastTimestamp = current
            self.lastSequence = 0
        }
        
        return current * 100 + Int64(self.lastSequence)
    }
    
    func ackMessage(_ sId: Int64, _ msgId: Int64) {
        ackLock.lock()
        if self.needAckDic[sId] == nil {
            self.needAckDic[sId] = Set()
        }
        self.needAckDic[sId]!.insert(msgId)
        ackLock.unlock()
    }
    
    func ackMessages() {
        ackLock.lock()
        for (k, v) in self.needAckDic {
            if v.count > 0 {
                self.ackServerMessage(k, v)
            }
        }
        ackLock.unlock()
    }
    
    func ackMessageSuccess(_ sId: Int64, _ msgIds: Set<Int64>) {
        ackLock.lock()
        var messageIds = needAckDic[sId]
        if messageIds != nil {
            for id in msgIds {
                messageIds!.remove(id)
            }
            needAckDic[sId] = messageIds
        }
        ackLock.unlock()
    }
    
    func ackServerMessage(_ sId: Int64, _ msgIds: Set<Int64>) {
        messageApi.rx
            .request(.ackMsgs(AckMsgBean(sId: sId, uId: IMManager.shared.uId, msgIds: msgIds)))
            .asObservable()
            .compose(DefaultRxTransformer.response2ErrorBean())
            .compose(DefaultRxTransformer.io2Io())
            .subscribe(
                onNext: { value in
                    self.ackMessageSuccess(sId, msgIds)
                },
                onError: { error in
                    DDLogError(error)
                }
            ).disposed(by: disposeBag)
    }
    
    func deleteServerMessages(_ sId: Int64, _ msgIds: Array<Int64>) -> Observable<ErrorBean> {
        return messageApi.rx
            .request(.deleteMsgs(DeleteMsgBean(sId: sId, uId: IMManager.shared.uId, msgIds: msgIds)))
            .asObservable()
            .compose(DefaultRxTransformer.response2ErrorBean())
    }
    
    func deleteMessages(_ sId: Int64, _ messages: Array<Message>, _ deleteServer: Bool) -> Observable<Bool> {
        if (deleteServer) {
            var ids = Array<Int64>()
            for message in messages {
                ids.append(message.id)
            }
            return self.deleteServerMessages(sId, ids).flatMap({
                (value) -> Observable<Bool> in
                if (value.code == 200) {
                    return self.deleteLocalMessages(messages)
                }
                return Observable.error(Exception.IMHttp(value.code, value.message))
            })
        }
        return self.deleteLocalMessages(messages)
    }
    
    func deleteLocalMessages(_ messages: Array<Message>) -> Observable<Bool> {
        return Observable.create({observer -> Disposable in
            do {
                try IMManager.shared.database.messageDao.deleteMessages(messages)
                observer.onNext(true)
            } catch {
                observer.onNext(false)
            }
            observer.onCompleted()
            return Disposables.create()
        })
    }
    
    func onNewMessage(_ msg: Message) {
        msgLock.lock()
        getMsgProcessor(msg.type).received(msg)
        processSessionByMessage(msg)
        msgLock.unlock()
    }
    
    func onNewMessage(_ bean: MessageBean) {
        let msg = bean.toMessage()
        onNewMessage(msg)
    }
    
    func resendMessage(_ message: Message) {
        getMsgProcessor(message.type).resend(message)
    }
    
    
    func sendMessage(_ sId: Int64, _ type: Int, _ msgBody: String) {
        getMsgProcessor(type).sendMessage(msgBody, sId)
    }
    
    func sendMessageToServer(_ bean: MessageBean) -> Observable<MessageBean> {
        return messageApi.rx
            .request(.sendMsg(bean))
            .asObservable()
            .compose(DefaultRxTransformer.response2Bean(MessageBean.self))
    }
    
    func syncLatestMessagesFromServer(_ cTime: Int64, _ offset: Int, _ size: Int) -> Observable<Array<MessageBean>> {
        return messageApi.rx
            .request(.getLatestMsg(IMManager.shared.uId, offset, size, cTime))
            .asObservable()
            .compose(DefaultRxTransformer.response2Bean(ListBean<MessageBean>.self))
            .flatMap({ (listBean) -> Observable<Array<MessageBean>> in
                return Observable.just(listBean.data)
            })
    }
    
    func syncOfflineMessages(_ time: Int64, _ offset: Int, _ size: Int) {
        DDLogDebug("MessageModule: syncOfflineMessages \(time), \(offset), \(size)")
        self.syncLatestMessagesFromServer(time, offset, size)
            .compose(DefaultRxTransformer.io2Io())
            .subscribe(onNext: { beanArray in
                do {
                    var msgs = Array<Message>()
                    var sessionMsgs = [Int64: [Message]]()
                    for bean in beanArray {
                        let msg = bean.toMessage()
                        if msg.fUId == IMManager.shared.uId {
                            msg.status = MsgStatus.AlreadyReadInServer.rawValue
                        }
                        msgs.append(msg)
                        if sessionMsgs[msg.sid] == nil {
                            sessionMsgs[msg.sid] = [Message]()
                        }
                        sessionMsgs[msg.sid]?.append(msg)
                    }
                    // 批量插入消息
                    try IMManager.shared.database.messageDao.insertMessages(msgs)
                    
                    // 插入ack
                    for msg in msgs {
                        self.ackMessage(msg.sid, msg.msgId)
                    }
                    
                    // 更新每个session的最后一条消息
                    for (sid, msgs) in sessionMsgs {
                        SwiftEventBus.post(IMEvent.MsgsNew.rawValue, sender: (sid, msgs))
                        let lastMsg = msgs.last
                        if lastMsg != nil {
                            self.processSessionByMessage(lastMsg!)
                        }
                    }
                } catch {
                    DDLogError(error)
                }
                
                if (beanArray.count > 0) {
                    let severTime = IMManager.shared.severTime
                    _ = self.setOfflineMsgSyncTime(severTime)
                }
                
                if (beanArray.count >= size) {
                    self.syncOfflineMessages(time, offset + beanArray.count, size)
                }
            })
            .disposed(by: disposeBag)
    }
    
    func syncAllMessages(_ offset: Int, _ size: Int) {
        let time: Int64 = 0
        self.syncLatestMessagesFromServer(time, offset, size)
            .compose(DefaultRxTransformer.io2Io())
            .subscribe(onNext: { beanArray in
                for bean in beanArray {
                    self.onNewMessage(bean)
                }
                if (beanArray.count >= size) {
                    self.syncAllMessages(offset + beanArray.count, size)
                }
            })
            .disposed(by: disposeBag)
    }
    
    func syncLatestSessionsFromServer(_ offset: Int, _ size: Int) -> Observable<Array<SessionBean>> {
        return Observable.just(Array())
    }
    
    func getSession(_ uId: Int64, _ map: Dictionary<String, Any>?) -> Observable<Session> {
        return Observable.create({observer -> Disposable in
            do {
                var session = try IMManager.shared.database.sessionDao.querySessionByEntityId(uId, SessionType.Single.rawValue)
                if (session == nil) {
                    session = Session()
                    session?.type = SessionType.Single.rawValue
                    session?.entityId = uId
                }
                observer.onNext(session!)
            } catch {
                observer.onError(error)
            }
            observer.onCompleted()
            return Disposables.create()
        }).flatMap({ (session) -> Observable<Session> in
            if (session.id > 0) {
                return Observable.just(session)
            } else {
                return self.getSessionFromServerByEntityId(uId, SessionType.Single.rawValue, map).flatMap({
                    (bean) -> Observable<Session> in
                    return Observable.just(bean.toSession())
                })
            }
        })
    }
    
    func getSessionFromServerByEntityId(_ entityId: Int64, _ type: Int, _ map: Dictionary<String, Any>?) -> Observable<SessionBean> {
        let bean = CreateSessionBean(type: type, entityId: nil, members: [IMManager.shared.uId, entityId])
        return sessionApi.rx
            .request(.createSession(bean))
            .asObservable()
            .compose(DefaultRxTransformer.response2Bean(SessionBean.self))
    }
    
    func querySessionFromServer(_ sId: Int64) -> Observable<SessionBean> {
        let selfUId = IMManager.shared.uId
        return sessionApi.rx
            .request(.querySession(selfUId, sId))
            .asObservable()
            .compose(DefaultRxTransformer.response2Bean(SessionBean.self))
    }
    
    func queryLocalSession(_ sId: Int64) -> Observable<Session> {
        return Observable.create({observer -> Disposable in
            do {
                var session = try IMManager.shared.database.sessionDao.querySessionById(sId)
                if session == nil {
                    session = Session()
                    session!.id = sId
                }
                observer.onNext(session!)
            } catch {
                observer.onError(error)
                DDLogError(error)
            }
            observer.onCompleted()
            return Disposables.create()
        })
    }
    
    func querySession(_ sId: Int64) -> Observable<Session> {
        return queryLocalSession(sId).flatMap({ (session) -> Observable<Session> in
            if (session.id == 0 || session.type == 0) {
                return self.querySessionFromServer(sId).flatMap({ (bean) -> Observable<Session> in
                    return Observable.just(bean.toSession())
                })
            }
            return Observable.just(session)
            
        })
    }
    
    func syncAllSessionsFromServer(_ offset: Int, _ size: Int) -> Observable<Array<SessionBean>> {
        return Observable.just(Array())
    }
    
    func queryLocalSessions(_ size: Int, _ mTime: Int64) -> Observable<Array<Session>> {
        return Observable.create({observer -> Disposable in
            do {
                let sessions = try IMManager.shared.database.sessionDao.querySessions(size, mTime)
                if (sessions != nil) {
                    observer.onNext(sessions!)
                } else {
                    observer.onNext(Array())
                }
            } catch {
                observer.onError(error)
                DDLogError(error)
            }
            observer.onCompleted()
            return Disposables.create()
        })
    }
    
    func queryLocalMessages(_ sId: Int64, _ cTime: Int64, _ size: Int) -> Observable<Array<Message>> {
        return Observable.create({observer -> Disposable in
            do {
                let messages = try IMManager.shared.database.messageDao.queryMessageBySidAndCTime(sId, cTime, size)
                if (messages != nil) {
                    observer.onNext(messages!)
                } else {
                    observer.onNext(Array())
                }
            } catch {
                observer.onError(error)
                DDLogError(error)
            }
            observer.onCompleted()
            return Disposables.create()
        })
    }
    
    func deleteServerSession(_ sessionList: Array<Session>) -> Observable<Int> {
        return Observable.just(0)
    }
    
    func deleteLocalSession(_ sessionList: Array<Session>) -> Observable<Int> {
        return Observable.just(0)
    }
    
    func deleteSession(_ sessionList: Array<Session>, _ deleteServer: Bool) -> Observable<Bool> {
        return Observable.just(false)
    }
    
    func signMessageReadBySessionId(_ sId: Int64) {
        
    }
    
    func onSignalReceived(_ subType: Int, _ body: String) {
        if subType == 0 {
            do {
                let msgBean = try JSONDecoder().decode(
                    MessageBean.self,
                    from: body.data(using: String.Encoding.utf8)!)
                onNewMessage(msgBean)
            } catch {
                DDLogError(error)
            }
        } else {
            DDLogError(String(format: "subType: %d message not support", subType))
        }
    }
    
    func processSessionByMessage(_ msg: Message) {
        let sessionDao = IMManager.shared.database.sessionDao
        queryLocalSession(msg.sid)
            .flatMap({ (session) -> Observable<Session> in
                if (session.entityId == 0) {
                    return self.querySessionFromServer(session.id)
                        .flatMap { (bean) -> Observable<Session> in
                        let s = bean.toSession()
                        try sessionDao.insertSessions(s)
                        return Observable.just(s)
                    }
                }
                return Observable.just(session)
            })
            .compose(DefaultRxTransformer.io2Io())
            .subscribe(
                onNext: { s in
                    if s.mTime < msg.cTime {
                        let processor = self.getMsgProcessor(msg.type)
                        s.lastMsg = processor.getSessionDesc(msg: msg)
                        s.mTime = msg.cTime
                        do {
                            try sessionDao.updateSessions(s)
                            SwiftEventBus.post(IMEvent.SessionNew.rawValue, sender: s)
                        } catch {
                            DDLogError(error)
                        }
                    }
                },
                onError: { error in
                    DDLogError(error)
                }
            ).disposed(by: disposeBag)
        
    }
    
    func setOfflineMsgSyncTime(_ time: Int64) -> Bool {
        let key = "/\(IMManager.shared.uId)/user_sync_time"
        let saveTime = IMManager.shared.severTime
        UserDefaults.standard.setValue(saveTime, forKey: key)
        return UserDefaults.standard.synchronize()
    }
    
    func getOfflineMsgLastSyncTime() -> Int64 {
        let key = "/\(IMManager.shared.uId)/user_sync_time"
        let value = UserDefaults.standard.object(forKey: key)
        let time = value == nil ? 0 : (value as! Int64 )
        return time
    }
}
