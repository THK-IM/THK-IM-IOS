//
//  DefaultMessageModule.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/18.
//

import Foundation
import Moya
import RxSwift
import CocoaLumberjack
import AVFoundation

open class DefaultMessageModule : MessageModule {
    
    
    private var processorDic = [Int: IMBaseMsgProcessor]()
    private var disposeBag = DisposeBag()
    private var lastTimestamp : Int64 = 0
    private var lastSequence : Int = 0
    private let epoch: Int64 = 1288834974657
    private let snowFlakeMachine: Int64 = 1 // 雪花算法机器编号 IOS:1 Android: 2
    
    private let idLock = NSLock()
    private let ackLock = NSLock()
    private let ackMessagePublishSubject = PublishSubject<Int>()
    private var needAckDic = [Int64: Set<Int64>]()
    
    init() {
        self.initAckMessagePublishSubject()
    }
    
    private func initAckMessagePublishSubject() {
        let scheduler = RxSwift.ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global())
        ackMessagePublishSubject.debounce(self.ackInterval(), scheduler: scheduler)
            .subscribe(onNext: { [weak self] _ in
                self?.ackMessagesToServer()
            }).disposed(by: self.disposeBag)
    }
    
    public func reset() {
        clearAckCache()
        self.disposeBag = DisposeBag()
        for (_, v) in processorDic {
            v.reset()
        }
        initAckMessagePublishSubject()
    }
    
    open func ackInterval() -> RxTimeInterval {
        return RxTimeInterval.seconds(5)
    }
    
    
    open func getOfflineMsgCountPerRequest() -> Int {
        return 200
    }
    
    open func getSessionCountPerRequest() -> Int {
        return 200
    }
    
    private func setOfflineMsgSyncTime(_ time: Int64) -> Bool {
        let key = "/\(IMCoreManager.shared.uId)/msg_sync_time"
        let saveTime = IMCoreManager.shared.severTime
        UserDefaults.standard.setValue(saveTime, forKey: key)
        return UserDefaults.standard.synchronize()
    }
    
    private func getOfflineMsgLastSyncTime() -> Int64 {
        let key = "/\(IMCoreManager.shared.uId)/msg_sync_time"
        let value = UserDefaults.standard.object(forKey: key)
        let time = value == nil ? 0 : (value as! Int64 )
        return time
    }
    
    private func setSessionLastSyncTime(_ time: Int64) -> Bool {
        let key = "/\(IMCoreManager.shared.uId)/session_sync_time"
        let saveTime = IMCoreManager.shared.severTime
        UserDefaults.standard.setValue(saveTime, forKey: key)
        return UserDefaults.standard.synchronize()
    }
    
    private func getSessionLastSyncTime() -> Int64 {
        let key = "/\(IMCoreManager.shared.uId)/session_sync_time"
        let value = UserDefaults.standard.object(forKey: key)
        let time = value == nil ? 0 : (value as! Int64 )
        return time
    }
    
    public func registerMsgProcessor(_ processor: IMBaseMsgProcessor) {
        processorDic[processor.messageType()] = processor
    }
    
    public func getMsgProcessor(_ msgType: Int) -> IMBaseMsgProcessor {
        let processor = processorDic[msgType]
        return (processor != nil) ? (processor!) : processorDic[0]!
    }
    
    public func syncOfflineMessages() {
        let lastTime = self.getOfflineMsgLastSyncTime()
        let count = getOfflineMsgCountPerRequest()
        let uId = IMCoreManager.shared.uId
        IMCoreManager.shared.api.getLatestMessages(uId, lastTime, count)
            .compose(RxTransformer.shared.io2Io())
            .subscribe(onNext: { messageArray in
                do {
                    DDLogInfo("processSessionByMessage syncOfflineMessages: \(messageArray.count)")
                    var sessionMsgs = [Int64: [Message]]()
                    var unProcessMsgs = [Message]()
                    var needReprocessMsgs = [Message]()
                    for msg in messageArray {
                        DDLogInfo("processSessionByMessage syncOfflineMessages: \(msg.type) \(msg.content ?? "")")
                        if msg.fromUId == IMCoreManager.shared.uId {
                            msg.operateStatus = msg.operateStatus |
                            MsgOperateStatus.Ack.rawValue |
                            MsgOperateStatus.ClientRead.rawValue |
                            MsgOperateStatus.ServerRead.rawValue
                        }
                        msg.sendStatus = MsgSendStatus.Success.rawValue
                        if (self.getMsgProcessor(msg.type).needReprocess(msg: msg)) {
                            // 状态操作消息交给对应消息处理器自己处理
                            needReprocessMsgs.append(msg)
                        } else {
                            // 其他消息批量处理
                            if sessionMsgs[msg.sessionId] == nil {
                                sessionMsgs[msg.sessionId] = [Message]()
                            }
                            sessionMsgs[msg.sessionId]?.append(msg)
                            unProcessMsgs.append(msg)
                        }
                    }
                    // 批量插入消息
                    if unProcessMsgs.count > 0 {
                        try IMCoreManager.shared.database.messageDao().insertOrIgnore(unProcessMsgs)
                        // 插入ack
                        for msg in unProcessMsgs {
                            if msg.operateStatus & MsgOperateStatus.Ack.rawValue == 0 {
                                self.ackMessageToCache(msg)
                            }
                        }
                    }
                    
                    for needReprocessMsg in needReprocessMsgs {
                        self.getMsgProcessor(needReprocessMsg.type).received(needReprocessMsg)
                    }
                    
                    // 更新每个session的最后一条消息
                    for (sid, msgs) in sessionMsgs {
                        SwiftEventBus.post(IMEvent.BatchMsgNew.rawValue, sender: (sid, msgs))
                        let lastMsg = try IMCoreManager.shared.database.messageDao().findLastMessageBySessionId(sid)
                        if lastMsg != nil {
                            self.processSessionByMessage(lastMsg!)
                        }
                    }
                } catch {
                    DDLogError("\(error)")
                }
                
                if (messageArray.last != nil) {
                    let severTime = messageArray.last!.cTime
                    let success = self.setOfflineMsgSyncTime(severTime)
                    if (success && messageArray.count >= count) {
                        self.syncOfflineMessages()
                    }
                }
                
            })
            .disposed(by: disposeBag)
    }
    
    public func syncLatestSessionsFromServer() {
        let lastTime = self.getSessionLastSyncTime()
        let count = getSessionCountPerRequest()
        let uId = IMCoreManager.shared.uId
        IMCoreManager.shared.api.queryUserLatestSessions(uId, count, lastTime, nil)
            .compose(RxTransformer.shared.io2Io())
            .subscribe(onNext: { sessions in
                var needDelGroupIds = Set<Int64>()
                var needDelSIds = Set<Int64>()
                var needDelSessions = [Session]()
                var needUpdateSessions = [Session]()
                
                for s in sessions {
                    if (s.deleted == 1) {
                        needDelSIds.insert(s.id)
                        needDelSessions.append(s)
                        if (s.type == SessionType.Group.rawValue ||
                            s.type == SessionType.SuperGroup.rawValue) {
                            needDelGroupIds.insert(s.entityId)
                        }
                    } else {
                        needUpdateSessions.append(s)
                    }
                }
                
                if (!needDelSessions.isEmpty) {
                    try? IMCoreManager.shared.database.sessionDao().delete(needDelSessions)
                    try? IMCoreManager.shared.database.messageDao().deleteBySessionIds(needDelSIds)
                }
                if (!needDelGroupIds.isEmpty) {
                    try? IMCoreManager.shared.database.groupDao().deleteByIds(needDelGroupIds)
                }
                if (!needUpdateSessions.isEmpty) {
                    for new in needUpdateSessions {
                        let dbSession = try? IMCoreManager.shared.database.sessionDao().findById(new.id)
                        if dbSession != nil {
                            dbSession!.parentId = new.parentId
                            dbSession!.entityId = new.entityId
                            dbSession!.name = new.name
                            dbSession!.parentId = new.parentId
                            dbSession!.noteName = new.noteName
                            dbSession!.type = new.type
                            dbSession!.remark = new.remark
                            dbSession!.role = new.role
                            dbSession!.status = new.status
                            dbSession!.mute = new.mute
                            dbSession!.extData = new.extData
                            dbSession!.topTimestamp = new.topTimestamp
                            try? IMCoreManager.shared.database.sessionDao().update([dbSession!])
                        } else {
                            try? IMCoreManager.shared.database.sessionDao().insertOrUpdate([new])
                        }
                    }
                }
                
                
                if (!sessions.isEmpty) {
                    let success = self.setSessionLastSyncTime(sessions.last!.mTime)
                    if (success && sessions.count >= count) {
                        self.syncLatestSessionsFromServer()
                    }
                }
                
            })
            .disposed(by: disposeBag)
    }
    
    public func getSession(_ sessionId: Int64) -> Observable<Session> {
        return Observable.create({observer -> Disposable in
            do {
                var session = try IMCoreManager.shared.database.sessionDao().findById(sessionId)
                if (session == nil) {
                    session = Session.emptySession()
                }
                observer.onNext(session!)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }).flatMap({ (session) -> Observable<Session> in
            if (session.id > 0) {
                return Observable.just(session)
            } else {
                return IMCoreManager.shared.api.queryUserSession(IMCoreManager.shared.uId, sessionId)
                    .flatMap({ session in
                        try? IMCoreManager.shared.database.sessionDao().insertOrIgnore([session])
                        return Observable.just(session)
                    })
            }
        })
    }
    
    
    public func getSession(_ entityId: Int64, _ type: Int) -> Observable<Session> {
        return Observable.create({observer -> Disposable in
            do {
                var session = try IMCoreManager.shared.database.sessionDao().findByEntityId(entityId, type)
                if (session == nil) {
                    session = Session.emptySession()
                }
                observer.onNext(session!)
                observer.onCompleted()
            } catch {
                observer.onError(error)
            }
            return Disposables.create()
        }).flatMap({ (session) -> Observable<Session> in
            if (session.id > 0) {
                return Observable.just(session)
            } else {
                return IMCoreManager.shared.api.queryUserSession(IMCoreManager.shared.uId, entityId, type)
                    .flatMap({ session in
                        try? IMCoreManager.shared.database.sessionDao().insertOrIgnore([session])
                        return Observable.just(session)
                    })
            }
        })
    }
    
    public func queryLocalSessions(_ parentId: Int64, _ count: Int, _ mTime: Int64) -> Observable<Array<Session>> {
        return Observable.create({observer -> Disposable in
            do {
                let sessions = try IMCoreManager.shared.database.sessionDao().findByParentId(parentId, count, mTime)
                if (sessions != nil) {
                    observer.onNext(sessions!)
                } else {
                    observer.onNext(Array())
                }
                observer.onCompleted()
            } catch {
                observer.onError(error)
                DDLogError("\(error)")
            }
            return Disposables.create()
        })
    }
    
    public func queryLocalMessages(_ sessionId: Int64, _ cTime: Int64, _ count: Int) -> Observable<Array<Message>> {
        return Observable.create({observer -> Disposable in
            let messages = IMCoreManager.shared.database.messageDao().findBySidAfterCTime(sessionId, cTime, count)
            observer.onNext(messages)
            observer.onCompleted()
            return Disposables.create()
        })
    }
    
    /**
     * 批量删除多条Session
     */
    public func deleteSession(_ session: Session, _ deleteServer: Bool) -> Observable<Void> {
        if (deleteServer) {
            return self.deleteServerSession(session)
                .concat(self.deleteLocalSession(session))
        }
        return self.deleteLocalSession(session)
    }
    
    /**
     * 更新session
     */
    public func updateSession(_ session: Session, _ updateSever: Bool) -> Observable<Void> {
        if (updateSever) {
            return self.updateServerSession(session)
                .concat(self.updateLocalSession(session))
        }
        return self.updateLocalSession(session)
    }
    
    public func onNewMessage(_ msg: Message) {
        getMsgProcessor(msg.type).received(msg)
    }
    
    public func generateNewMsgId() -> Int64 {
        idLock.lock()
        defer {
            idLock.unlock()
        }
        let current = IMCoreManager.shared.severTime
        if (current == self.lastTimestamp) {
            self.lastSequence += 1
        } else {
            self.lastTimestamp = current
            self.lastSequence = 0
        }
        return (current-epoch) << 22 + Int64(snowFlakeMachine << 12) + Int64(self.lastSequence)
    }
    
    public func sendMessage(_ sessionId: Int64, _ type: Int, _ body: Codable?, _ data: Codable?, _ atUser: String? = nil,
                            _ replyMsgId: Int64? = nil, _ sendResult: IMSendMsgResult? = nil){
        let processor = getMsgProcessor(type)
        processor.sendMessage(sessionId, body, data, atUser, replyMsgId, sendResult)
    }
    
    public func sendMessageToServer(_ message: Message) -> Observable<Message> {
        return IMCoreManager.shared.api.sendMessageToServer(msg: message)
    }
    
    public func ackMessageToCache(_ msg: Message) {
        ackLock.lock()
        if msg.sessionId > 0 && msg.msgId > 0 {
            if msg.operateStatus & MsgOperateStatus.Ack.rawValue == 0 {
                if self.needAckDic[msg.sessionId] == nil {
                    self.needAckDic[msg.sessionId] = Set()
                }
                self.needAckDic[msg.sessionId]!.insert(msg.msgId)
            }
        }
        ackLock.unlock()
        self.ackMessagePublishSubject.onNext(0)
    }
    
    private func ackMessageSuccess(_ sessionId: Int64, _ msgIds: Set<Int64>) {
        ackLock.lock()
        do {
            try IMCoreManager.shared.database
                .messageDao()
                .updateOperationStatus(sessionId, msgIds.compactMap({$0}), MsgOperateStatus.Ack.rawValue)
        } catch {
            DDLogError("ackMessageSuccess error: \(error)")
        }
        var messageIds = needAckDic[sessionId]
        if messageIds != nil {
            for id in msgIds {
                messageIds!.remove(id)
            }
            needAckDic[sessionId] = messageIds
        }
        ackLock.unlock()
    }
    
    private func clearAckCache() {
        ackLock.lock()
        needAckDic.removeAll()
        ackLock.unlock()
    }
    
    
    private func ackServerMessage(_ sessionId: Int64, _ msgIds: Set<Int64>) {
        IMCoreManager.shared.api.ackMessages(IMCoreManager.shared.uId, sessionId, msgIds)
            .compose(RxTransformer.shared.io2Io())
            .subscribe(
                onError: { error in
                    DDLogError("\(error)")
                },
                onCompleted: {
                    self.ackMessageSuccess(sessionId, msgIds)
                }
            ).disposed(by: disposeBag)
    }
    
    public func ackMessagesToServer() {
        ackLock.lock()
        for (k, v) in self.needAckDic {
            if v.count > 0 {
                print("ackMessagesToServer \(k)")
                self.ackServerMessage(k, v)
            }
        }
        ackLock.unlock()
    }
    
    private func deleteServerMessages(_ sessionId: Int64, _ msgIds: Set<Int64>) -> Observable<Void> {
        return IMCoreManager.shared.api.deleteMessages(IMCoreManager.shared.uId, sessionId, msgIds)
    }
    
    private func deleteLocalMessages(_ messages: Array<Message>) -> Observable<Void> {
        return Observable.create({observer -> Disposable in
            do {
                try IMCoreManager.shared.database.messageDao().delete(messages)
                SwiftEventBus.post(IMEvent.BatchMsgDelete.rawValue, sender: messages)
            } catch {
                observer.onError(error)
            }
            observer.onCompleted()
            return Disposables.create()
        })
    }
    
    public func deleteMessages(_ sessionId: Int64, _ messages: Array<Message>, _ deleteServer: Bool) -> Observable<Void> {
        if (deleteServer) {
            var ids = Set<Int64>()
            for message in messages {
                if message.msgId > 0 { // msgId 大于0 才是正确的服务端消息id
                    ids.insert(message.msgId)
                }
            }
            return self.deleteServerMessages(sessionId, ids)
                .concat(self.deleteLocalMessages(messages))
        }
        return self.deleteLocalMessages(messages)
    }
    
    public func processSessionByMessage(_ msg: Message) {
        // id为0的session不展现给用户
        if (msg.sessionId == 0) {
            return 
        }
        self.getSession(msg.sessionId)
            .compose(RxTransformer.shared.io2Io())
            .subscribe(
                onNext: { [weak self] s in
                    do {
                        guard let sf = self else {
                            return
                        }
                        let unReadCount = try IMCoreManager.shared.database.messageDao().getUnReadCount(msg.sessionId)
                        if (s.mTime < msg.mTime || s.unreadCount != unReadCount) {
                            let processor = self?.getMsgProcessor(msg.type)
                            var statusText = ""
                            if (msg.sendStatus == MsgSendStatus.Sending.rawValue || msg.sendStatus == MsgSendStatus.Init.rawValue) {
                                statusText = "[⬆️]"
                            } else if (msg.sendStatus == MsgSendStatus.Failed.rawValue) {
                                statusText = "[❗]"
                            }
                            s.lastMsg = statusText + (processor?.getSessionDesc(msg: msg) ?? "")
                            s.unreadCount = unReadCount
                            s.mTime = msg.cTime
                            try IMCoreManager.shared.database.sessionDao().insertOrUpdate([s])
                            SwiftEventBus.post(IMEvent.SessionNew.rawValue, sender: s)
                            
                            sf.notifyNewMessage(s, msg)
                        }
                    } catch {
                        DDLogError("processSessionByMessage \(error)")
                    }
                },
                onError: { error in
                    DDLogError("processSessionByMessage \(error)")
                }
            ).disposed(by: disposeBag)
    }
    
    public func notifyNewMessage(_ session: Session, _ message: Message) {
        if (message.type < 0 || message.fromUId == IMCoreManager.shared.uId) {
            return
        }
        if (session.status & (SessionStatus.Silence.rawValue) > 0) {
            return
        }
        AppUtils.newMessageNotify()
    }
    
    public func onSignalReceived(_ type: Int, _ body: String) {
        do {
            let msgBean = try JSONDecoder().decode(
                MessageVo.self,
                from: body.data(using: String.Encoding.utf8)!)
            let msg = msgBean.toMessage()
            onNewMessage(msg)
        } catch {
            DDLogError("\(error)")
        }
    }
    
    
    private func deleteLocalSession(_ session: Session) -> Observable<Void> {
        return Observable.create({observer -> Disposable in
            do {
                try IMCoreManager.shared.database.messageDao().deleteBySessionId(session.id)
                try IMCoreManager.shared.database.sessionDao().delete([session])
            } catch {
                observer.onError(error)
            }
            SwiftEventBus.post(IMEvent.SessionDelete.rawValue, sender: session)
            observer.onCompleted()
            return Disposables.create()
        })
    }
    
    private func deleteServerSession(_ session: Session) -> Observable<Void> {
        return IMCoreManager.shared.api.deleteUserSession(IMCoreManager.shared.uId, session: session)
    }
    
    private func updateLocalSession(_ session: Session) -> Observable<Void> {
        return Observable.create({ observer -> Disposable in
            do {
                try IMCoreManager.shared.database.sessionDao().update([session])
            } catch {
                observer.onError(error)
            }
            SwiftEventBus.post(IMEvent.SessionUpdate.rawValue, sender: session)
            observer.onCompleted()
            return Disposables.create()
        })
    }
    
    private func updateServerSession(_ session: Session) -> Observable<Void> {
        return IMCoreManager.shared.api.updateUserSession(IMCoreManager.shared.uId, session: session)
    }
    
    
    public func querySessionMembers(_ sessionId: Int64) -> RxSwift.Observable<Array<SessionMember>> {
        return Observable.create({ observer -> Disposable in
            let members = IMCoreManager.shared.database.sessionMemberDao().findBySessionId(sessionId)
            observer.onNext(members)
            observer.onCompleted()
            return Disposables.create()
        }).flatMap({ members -> Observable<Array<SessionMember>> in
            if (members.count == 0) {
                return self.queryLastSessionMember(sessionId, 100)
            } else {
                return Observable.just(members)
            }
        })
    }
    
    private func queryLastSessionMember(_ sessionId: Int64, _ count: Int) -> Observable<Array<SessionMember>> {
        return Observable.just(sessionId).flatMap({ sessionId -> Observable<Int64> in
            let mTime = IMCoreManager.shared.database.sessionDao().findMemberSyncTimeById(sessionId)
            return Observable.just(mTime)
        }).flatMap({ mTime -> Observable<Array<SessionMember>> in
            return IMCoreManager.shared.api.queryLatestSessionMembers(sessionId, mTime, nil, count)
                .flatMap({ members -> Observable<Array<SessionMember>> in
                    var inserts = Array<SessionMember>()
                    var deletes = Array<SessionMember>()
                    for m in members {
                        if (m.deleted == 0) {
                            inserts.append(m)
                        } else {
                            deletes.append(m)
                        }
                    }
                    let sessionMemberDao = IMCoreManager.shared.database.sessionMemberDao()
                    try sessionMemberDao.delete(deletes)
                    try sessionMemberDao.insertOrReplace(inserts)
                    if (!members.isEmpty) {
                        let lastMTime = members.last!.mTime
                        try IMCoreManager.shared.database.sessionDao().updateMemberSyncTime(sessionId, lastMTime)
                    }
                    if (members.count >= count) {
                        return self.querySessionMembers(sessionId)
                    } else {
                        let sessionMembers = sessionMemberDao.findBySessionId(sessionId)
                        return Observable.just(sessionMembers)
                    }
                })
        })
    }
    
    public func syncSessionMembers(_ sessionId: Int64) {
        self.queryLastSessionMember(sessionId, 100)
            .compose(RxTransformer.shared.io2Io())
            .subscribe(onNext: { _ in
                
            }).disposed(by: self.disposeBag)
    }
    
    
}
