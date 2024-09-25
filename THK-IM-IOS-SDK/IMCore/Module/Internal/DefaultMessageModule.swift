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
    
    public init() {
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
    
    open func getSessionMemberCountPerRequest() -> Int {
        return 100
    }
    
    open func setOfflineMsgSyncTime(_ time: Int64) -> Bool {
        let key = "/\(IMCoreManager.shared.env)/\(IMCoreManager.shared.uId)/msg_sync_time"
        UserDefaults.standard.setValue(time, forKey: key)
        return UserDefaults.standard.synchronize()
    }
    
    open func getOfflineMsgLastSyncTime() -> Int64 {
        let key = "/\(IMCoreManager.shared.env)/\(IMCoreManager.shared.uId)/msg_sync_time"
        let value = UserDefaults.standard.object(forKey: key)
        let time = value == nil ? 0 : (value as! Int64 )
        return time
    }
    
    open func setSessionLastSyncTime(_ time: Int64) -> Bool {
        let key = "/\(IMCoreManager.shared.env)/\(IMCoreManager.shared.uId)/session_sync_time"
        UserDefaults.standard.setValue(time, forKey: key)
        return UserDefaults.standard.synchronize()
    }
    
    open func getSessionLastSyncTime() -> Int64 {
        let key = "/\(IMCoreManager.shared.env)/\(IMCoreManager.shared.uId)/session_sync_time"
        let value = UserDefaults.standard.object(forKey: key)
        let time = value == nil ? 0 : (value as! Int64 )
        return time
    }
    
    open func registerMsgProcessor(_ processor: IMBaseMsgProcessor) {
        processorDic[processor.messageType()] = processor
    }
    
    open func getMsgProcessor(_ msgType: Int) -> IMBaseMsgProcessor {
        let processor = processorDic[msgType]
        return (processor != nil) ? (processor!) : processorDic[0]!
    }
    
    open func batchProcessMessages(_ messages: Array<Message>, _ ack: Bool = true) throws {
        DDLogInfo("batchProcessMessages syncOfflineMessages: \(messages.count)")
        var sessionMsgs = [Int64: [Message]]()
        var unProcessMsgs = [Message]()
        var needReprocessMsgs = [Message]()
        for msg in messages {
            DDLogInfo("batchProcessMessages syncOfflineMessages: \(msg.type) \(msg.content ?? "")")
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
            if ack {
                for msg in unProcessMsgs {
                    if msg.operateStatus & MsgOperateStatus.Ack.rawValue == 0 {
                        self.ackMessageToCache(msg)
                    }
                }
            }
        }
        
        for needReprocessMsg in needReprocessMsgs {
            self.getMsgProcessor(needReprocessMsg.type).received(needReprocessMsg)
        }
        
        for (sid, msgs) in sessionMsgs {
            var referMsgIds = [Int64]()
            for m in msgs {
                if m.referMsgId != nil {
                    referMsgIds.append(m.referMsgId!)
                }
            }
            if !referMsgIds.isEmpty {
                let referMsgs = try? IMCoreManager.shared.database.messageDao().findByMsgIds(referMsgIds, sid)
                if referMsgs != nil {
                    for m in msgs {
                        for referMsg in referMsgs! {
                            if m.referMsgId == referMsg.msgId {
                                m.referMsg = referMsg
                                break
                            }
                        }
                    }
                }
            }
            SwiftEventBus.post(IMEvent.BatchMsgNew.rawValue, sender: (sid, msgs))
            
            // 更新每个session的最后一条消息
            let lastMsg = try IMCoreManager.shared.database.messageDao().findLastMessageBySessionId(sid)
            if lastMsg != nil {
                self.processSessionByMessage(lastMsg!)
            }
        }
    }
    
    open func syncOfflineMessages() {
        let lastTime = self.getOfflineMsgLastSyncTime()
        let count = getOfflineMsgCountPerRequest()
        let uId = IMCoreManager.shared.uId
        IMCoreManager.shared.api.getLatestMessages(uId, lastTime, count)
            .compose(RxTransformer.shared.io2Io())
            .subscribe(onNext: { [weak self] messageArray in
                guard let sf = self else {
                    return
                }
                do {
                    try sf.batchProcessMessages(messageArray)
                    if (messageArray.last != nil) {
                        let severTime = messageArray.last!.cTime
                        let success = sf.setOfflineMsgSyncTime(severTime)
                        if (success && messageArray.count >= count) {
                            sf.syncOfflineMessages()
                        }
                    }
                } catch {
                    DDLogError("syncOfflineMessages: \(error)")
                }
            })
            .disposed(by: disposeBag)
    }
    
    open func syncLatestSessionsFromServer() {
        let lastTime = self.getSessionLastSyncTime()
        let count = getSessionCountPerRequest()
        let uId = IMCoreManager.shared.uId
        IMCoreManager.shared.api.queryUserLatestSessions(uId, count, lastTime)
            .compose(RxTransformer.shared.io2Io())
            .subscribe(onNext: { [weak self] sessions in
                guard let sf = self else {
                    return
                }
                var needDelSIds = Set<Int64>()
                var needDelGroupIds = Set<Int64>()
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
                            dbSession!.mergeServerSession(new)
                            try? IMCoreManager.shared.database.sessionDao().update([dbSession!])
                        } else {
                            try? IMCoreManager.shared.database.sessionDao().insertOrUpdate([new])
                        }
                    }
                }
                
                if (!sessions.isEmpty) {
                    let success = sf.setSessionLastSyncTime(sessions.last!.mTime)
                    if (success && sessions.count >= count) {
                        sf.syncLatestSessionsFromServer()
                        return
                    }
                }
                // session 同步完了后开始同步超级群消息
                sf.syncSuperGroupMessages()
                
            })
            .disposed(by: disposeBag)
    }
    
    open func syncSessionMessage(_ session: Session) {
        let count = getOfflineMsgCountPerRequest()
        IMCoreManager.shared.api.querySessionMessages(
            sId: session.id, cTime: session.msgSyncTime + 1, offset: 0, count: count, asc: 1
        ).compose(RxTransformer.shared.io2Io())
            .subscribe(onNext: { [weak self] messages in
                guard let sf = self else {
                    return
                }
                do {
                    for m in messages {
                        if m.cTime <= session.mTime {
                            m.operateStatus = m.operateStatus | MsgOperateStatus.ClientRead.rawValue | MsgOperateStatus.ServerRead.rawValue
                        }
                    }
                    try sf.batchProcessMessages(messages, false)
                    if !messages.isEmpty {
                        let lastTime = messages.last?.cTime
                        if lastTime != nil {
                            try IMCoreManager.shared.database.sessionDao().updateMsgSyncTime(session.id, lastTime!)
                            if messages.count >= count {
                                session.msgSyncTime = lastTime!
                                sf.syncSessionMessage(session)
                            }
                        }
                    }
                } catch {
                    DDLogError("syncSessionMessage \(error)")
                }
            }).disposed(by: self.disposeBag)
    }
    
    /**
     * 同步超级群消息
     */
    open func syncSuperGroupMessages() {
        Observable.just("")
            .flatMap({ (it) -> Observable<Array<Session>?> in
                let sessions = try? IMCoreManager.shared.database.sessionDao().findAll(SessionType.SuperGroup.rawValue)
                return Observable.just(sessions)
            })
            .compose(RxTransformer.shared.io2Main())
            .subscribe(onNext: { [weak self] sessions in
                if let sf = self {
                    if sessions != nil {
                        for session in sessions! {
                            if (session.deleted == 0 && session.id > 0 && session.type == SessionType.SuperGroup.rawValue) {
                                sf.syncSessionMessage(session)
                            }
                        }
                    }
                }
            }).disposed(by: self.disposeBag)
    }
    
    
    /**
     * 同步超级群消息
     */
    open func syncSuperGroupMessages(session: Session) {
        if (session.deleted == 0 && session.id > 0 && session.type == SessionType.SuperGroup.rawValue) {
            self.syncSessionMessage(session)
        }
    }
    
    open func getSession(_ sessionId: Int64) -> Observable<Session> {
        return Observable.create({observer -> Disposable in
            do {
                var session = try IMCoreManager.shared.database.sessionDao().findById(sessionId)
                if (session == nil) {
                    session = Session.emptySession()
                }
                observer.onNext(session!)
//                observer.onCompleted()
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
                        if (session.id > 0 && session.deleted == 0) {
                            try? IMCoreManager.shared.database.sessionDao().insertOrIgnore([session])
                        }
                        return Observable.just(session)
                    })
            }
        })
    }
    
    
    open func getSession(_ entityId: Int64, _ type: Int) -> Observable<Session> {
        return Observable.create({observer -> Disposable in
            do {
                var session = try IMCoreManager.shared.database.sessionDao().findByEntityId(entityId, type)
                if (session == nil) {
                    session = Session.emptySession()
                }
                observer.onNext(session!)
//                observer.onCompleted()
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
                        if (session.id > 0 && session.deleted == 0) {
                            try? IMCoreManager.shared.database.sessionDao().insertOrIgnore([session])
                        }
                        return Observable.just(session)
                    })
            }
        })
    }
    
    open func queryLocalSessions(_ parentId: Int64, _ count: Int, _ mTime: Int64) -> Observable<Array<Session>> {
        return Observable.create({observer -> Disposable in
            do {
                let sessions = try IMCoreManager.shared.database.sessionDao().findByParentId(parentId, count, mTime)
                if (sessions != nil) {
                    observer.onNext(sessions!)
                } else {
                    observer.onNext(Array())
                }
//                observer.onCompleted()
            } catch {
                observer.onError(error)
                DDLogError("\(error)")
            }
            return Disposables.create()
        })
    }
    
    open func queryLocalMessages(_ sessionId: Int64, _ startTime: Int64, _ endTime: Int64, _ count: Int, _ excludeMsgId: [Int64]) -> Observable<Array<Message>> {
        return Observable.create({observer -> Disposable in
            DDLogDebug("queryLocalMessages  start: \(Date().timeMilliStamp)")
            let messages = IMCoreManager.shared.database.messageDao().findByTimeRange(sessionId, startTime, endTime, count, excludeMsgId)
            DDLogDebug("queryLocalMessages  end: \(Date().timeMilliStamp)")
            observer.onNext(messages)
//            observer.onCompleted()
            return Disposables.create()
        })
    }
    
    /**
     * 批量删除多条Session
     */
    open func deleteSession(_ session: Session, _ deleteServer: Bool) -> Observable<Void> {
        if (deleteServer) {
            return self.deleteServerSession(session)
                .concat(self.deleteLocalSession(session))
        }
        return self.deleteLocalSession(session)
    }
    
    /**
     * 更新session
     */
    open func updateSession(_ session: Session, _ updateSever: Bool) -> Observable<Void> {
        if (updateSever) {
            return self.updateServerSession(session)
                .concat(self.updateLocalSession(session))
        }
        return self.updateLocalSession(session)
    }
    
    open func onNewMessage(_ msg: Message) {
        DDLogInfo("MessageModule onNewMessage \(Thread.current.isMainThread ? "main": "io") \(msg.msgId) \(msg.type) \(msg.content ?? "")")
        getMsgProcessor(msg.type).received(msg)
    }
    
    open func generateNewMsgId() -> Int64 {
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
    
    open func sendMessage(_ sessionId: Int64, _ type: Int, _ body: Codable?, _ data: Codable?, _ atUser: String? = nil,
                            _ replyMsgId: Int64? = nil, _ sendResult: IMSendMsgResult? = nil){
        let processor = getMsgProcessor(type)
        processor.sendMessage(sessionId, body, data, atUser, replyMsgId, sendResult)
    }
    
    open func sendMessageToServer(_ message: Message) -> Observable<Message> {
        return IMCoreManager.shared.api.sendMessageToServer(msg: message)
    }
    
    open func ackMessageToCache(_ msg: Message) {
        ackLock.lock()
        if msg.msgId > 0 {
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
    
    open func ackMessageSuccess(_ sessionId: Int64, _ msgIds: Set<Int64>) {
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
    
    open func clearAckCache() {
        ackLock.lock()
        needAckDic.removeAll()
        ackLock.unlock()
    }
    
    
    open func ackServerMessage(_ sessionId: Int64, _ msgIds: Set<Int64>) {
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
    
    open func ackMessagesToServer() {
        ackLock.lock()
        for (k, v) in self.needAckDic {
            if v.count > 0 {
                print("ackMessagesToServer \(k)")
                self.ackServerMessage(k, v)
            }
        }
        ackLock.unlock()
    }
    
    open func deleteServerMessages(_ sessionId: Int64, _ msgIds: Set<Int64>) -> Observable<Void> {
        return IMCoreManager.shared.api.deleteMessages(IMCoreManager.shared.uId, sessionId, msgIds)
    }
    
    open func deleteLocalMessages(_ messages: Array<Message>) -> Observable<Void> {
        return Observable.create({ [weak self] observer -> Disposable in
            do {
                try IMCoreManager.shared.database.messageDao().delete(messages)
                SwiftEventBus.post(IMEvent.BatchMsgDelete.rawValue, sender: messages)
                var sessionIds = Set<Int64>()
                for m in messages {
                    sessionIds.insert(m.sessionId)
                }
                for sessionId in sessionIds {
                    if let lastMsg = try? IMCoreManager.shared.database.messageDao().findLastMessageBySessionId(sessionId) {
                        self?.processSessionByMessage(lastMsg, true)
                    } else {
                        if let session = try IMCoreManager.shared.database.sessionDao().findById(sessionId) {
                            session.unreadCount = 0
                            session.lastMsg = ""
                            session.msgSyncTime = IMCoreManager.shared.severTime
                            try? IMCoreManager.shared.database.sessionDao().update([session])
                            SwiftEventBus.post(IMEvent.SessionUpdate.rawValue, sender: session)
                        }
                    }
                }
            } catch {
                observer.onError(error)
            }
            observer.onCompleted()
            return Disposables.create()
        })
    }
    
    open func deleteMessages(_ sessionId: Int64, _ messages: Array<Message>, _ deleteServer: Bool) -> Observable<Void> {
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
    
    open func deleteAllLocalSessionMessage(_ session: Session) -> Observable<Void> {
        return Observable.create({ observer -> Disposable in
            do {
                try IMCoreManager.shared.database.messageDao().deleteBySessionId(session.id)
                SwiftEventBus.post(IMEvent.SessionMessageClear.rawValue, sender: session)
                session.unreadCount = 0
                session.lastMsg = ""
                try IMCoreManager.shared.database.sessionDao().insertOrUpdate([session])
                SwiftEventBus.post(IMEvent.SessionUpdate.rawValue, sender: session)
            } catch {
                observer.onError(error)
            }
            observer.onCompleted()
            return Disposables.create()
        })
    }
    
    open func processSessionByMessage(_ msg: Message, _ forceNotify: Bool = false) {
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
                        if (s.id <= 0 || s.deleted == 1) {
                            return
                        }
                        let unReadCount = try IMCoreManager.shared.database.messageDao().getUnReadCount(msg.sessionId)
                        if (forceNotify || s.mTime <= msg.mTime || s.unreadCount != unReadCount || s.lastMsg == nil || (s.lastMsg!.isEmpty)) {
                            let processor = self?.getMsgProcessor(msg.type)
                            var statusText = ""
                            if (msg.sendStatus == MsgSendStatus.Sending.rawValue || 
                                msg.sendStatus == MsgSendStatus.Init.rawValue ||
                                msg.sendStatus == MsgSendStatus.Uploading.rawValue
                            ) {
                                statusText = "➡️"
                            } else if (msg.sendStatus == MsgSendStatus.Failed.rawValue) {
                                statusText = "❗"
                            }
                            var sender: String? = nil
                            if s.type != SessionType.Single.rawValue {
                                if msg.fromUId > 0 {
                                    sender = processor?.getSenderName(msg: msg)
                                }
                            }
                            var senderText = ""
                            if sender != nil {
                                senderText = "\(sender!):"
                            }
                            s.lastMsg = statusText + senderText + (processor?.sessionDesc(msg: msg) ?? "")
                            s.unreadCount = unReadCount
                            if s.mTime < msg.cTime {
                                s.mTime = msg.cTime
                            }
                            try IMCoreManager.shared.database.sessionDao().insertOrUpdate([s])
                            SwiftEventBus.post(IMEvent.SessionNew.rawValue, sender: s)
                            if (msg.operateStatus & MsgOperateStatus.ClientRead.rawValue == 0) &&
                                (msg.operateStatus & MsgOperateStatus.ServerRead.rawValue == 0) &&
                                (!sf.getMsgProcessor(msg.type).needReprocess(msg: msg)) {
                                sf.notifyNewMessage(s, msg)
                            }
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
    
    open func notifyNewMessage(_ session: Session, _ message: Message) {
        if (message.type < 0 || message.fromUId == IMCoreManager.shared.uId) {
            return
        }
        if (session.status & (SessionStatus.Silence.rawValue) > 0) {
            return
        }
        AppUtils.newMessageNotify()
    }
    
    open func onSignalReceived(_ type: Int, _ body: String) {
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
    
    
    open func deleteLocalSession(_ session: Session) -> Observable<Void> {
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
    
    open func deleteServerSession(_ session: Session) -> Observable<Void> {
        return IMCoreManager.shared.api.deleteUserSession(IMCoreManager.shared.uId, session: session)
    }
    
    open func updateLocalSession(_ session: Session) -> Observable<Void> {
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
    
    open func updateServerSession(_ session: Session) -> Observable<Void> {
        return IMCoreManager.shared.api.updateUserSession(IMCoreManager.shared.uId, session: session)
    }
    
    
    open func querySessionMembers(_ sessionId: Int64, _ forceServer: Bool = false) -> RxSwift.Observable<Array<SessionMember>> {
        let count = getSessionMemberCountPerRequest()
        if forceServer {
            return self.queryLastSessionMember(sessionId, count)
        } else {
            return Observable.create({ observer -> Disposable in
                let members = IMCoreManager.shared.database.sessionMemberDao().findBySessionId(sessionId)
                observer.onNext(members)
                return Disposables.create()
            }).flatMap({ members -> Observable<Array<SessionMember>> in
                if (members.count == 0) {
                    return self.queryLastSessionMember(sessionId, count)
                } else {
                    return Observable.just(members)
                }
            })
        }
        
    }
    
    open func queryLastSessionMember(_ sessionId: Int64, _ count: Int) -> Observable<Array<SessionMember>> {
        return Observable.just(sessionId).flatMap({ sessionId -> Observable<Int64> in
            let mTime = IMCoreManager.shared.database.sessionDao().findMemberSyncTimeById(sessionId)
            return Observable.just(mTime)
        }).flatMap({ mTime -> Observable<Array<SessionMember>> in
            return IMCoreManager.shared.api.queryLatestSessionMembers(sessionId, mTime, nil, count)
                .flatMap({ members -> Observable<Array<SessionMember>> in
                    let sessionMemberDao = IMCoreManager.shared.database.sessionMemberDao()
                    try sessionMemberDao.insertOrReplace(members)
                    if (!members.isEmpty) {
                        let lastMTime = members.last!.mTime
                        try IMCoreManager.shared.database.sessionDao().updateMemberSyncTime(sessionId, lastMTime)
                    }
                    if (members.count >= count) {
                        return self.queryLastSessionMember(sessionId, count)
                    } else {
                        let sessionMembers = sessionMemberDao.findBySessionId(sessionId)
                        let memberCount = sessionMemberDao.findSessionMemberCount(sessionId)
                        if let session = try? IMCoreManager.shared.database.sessionDao().findById(sessionId) {
                            if session.memberCount != memberCount {
                                session.memberCount = memberCount
                                try? IMCoreManager.shared.database.sessionDao().update([session])
                                SwiftEventBus.post(IMEvent.SessionUpdate.rawValue, sender: session)
                            }
                        }
                        return Observable.just(sessionMembers)
                    }
                })
        })
    }
    
    open func syncSessionMembers(_ sessionId: Int64) {
        self.queryLastSessionMember(sessionId, 100)
            .compose(RxTransformer.shared.io2Io())
            .subscribe(onNext: { _ in
                
            }).disposed(by: self.disposeBag)
    }
    
    /**
     * 设置所有消息已读
     */
    open func setAllMessageRead() -> Observable<Void> {
        return Observable.create({observer -> Disposable in
            do {
                try IMCoreManager.shared.database.messageDao().updateAllMsgReaded()
                try IMCoreManager.shared.database.sessionDao().updateAllSessionReaded()
            } catch {
                observer.onError(error)
            }
            observer.onCompleted()
            return Disposables.create()
        })
    }
    
    
}
