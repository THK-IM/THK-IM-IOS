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
    
    private var processorDic = [Int: BaseMsgProcessor]()
    private let disposeBag = DisposeBag()
    private var lastTimestamp : Int64 = 0
    private var lastSequence : Int = 0
    private var needAckDic = [Int64: Set<Int64>]()
    private let idLock = NSLock()
    private let ackLock = NSLock()
    private let msgLock = NSLock()
    
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
    
    func registerMsgProcessor(_ processor: BaseMsgProcessor) {
        processorDic[processor.messageType()] = processor
    }

    func getMsgProcessor(_ msgType: Int) -> BaseMsgProcessor {
        let processor = processorDic[msgType]
        return (processor != nil) ? (processor!) : processorDic[0]!
    }
    
    func syncOfflineMessages() {
        let lastTime = self.getOfflineMsgLastSyncTime()
        let count = 200
        IMCoreManager.shared.api.getLatestMessages(lastTime, 0, count)
           .compose(DefaultRxTransformer.io2Io())
           .subscribe(onNext: { messageArray in
               do {
                   var sessionMsgs = [Int64: [Message]]()
                   for msg in messageArray {
                       if msg.fromUId == IMCoreManager.shared.uId {
                           msg.operateStatus = msg.operateStatus | MsgOperateStatus.Ack.rawValue | MsgOperateStatus.ClientRead.rawValue | MsgOperateStatus.ServerRead.rawValue
                       }
                       msg.sendStatus = MsgSendStatus.Success.rawValue
                       if sessionMsgs[msg.sessionId] == nil {
                           sessionMsgs[msg.sessionId] = [Message]()
                       }
                       sessionMsgs[msg.sessionId]?.append(msg)
                   }
                   // 批量插入消息
                   try IMCoreManager.shared.database.messageDao.insertMessages(messageArray)

                   // 插入ack
                   for msg in messageArray {
                       self.ackMessageToCache(msg.sessionId, msg.msgId)
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

               if (messageArray.count > 0) {
                   let severTime = IMCoreManager.shared.severTime
                   _ = self.setOfflineMsgSyncTime(severTime)
               }

               if (messageArray.count >= count) {
                   self.syncOfflineMessages()
               }
           })
           .disposed(by: disposeBag)
    }
    
    func syncLatestSessionsFromServer(_ lastSyncTime: Int, _ count: Int) {
        // TODO
    }
    
    
    
    func createSession(_ entityId: Int64, _ sessionType: Int) -> Observable<Session> {
        return Observable.create({observer -> Disposable in
            do {
                var session = try IMCoreManager.shared.database.sessionDao.querySessionByEntityId(entityId, sessionType)
                if (session == nil) {
                    session = Session(
                        id: 0, type: 0, entityId: 0, status: 0, unreadCount: 0, cTime: 0, mTime: 0
                    )
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
                var members = Set<Int64>()
                members.insert(IMCoreManager.shared.uId)
                if sessionType == SessionType.Single.rawValue {
                    members.insert(entityId)
                }
                return IMCoreManager.shared.api.createSession(sessionType, entityId, members)
            }
        })
    }
    
    func getSession(_ sessionId: Int64) -> Observable<Session> {
        return Observable.create({observer -> Disposable in
            do {
                var session = try IMCoreManager.shared.database.sessionDao.querySessionById(sessionId)
                if (session == nil) {
                    session = Session(
                        id: 0, type: 0, entityId: 0, status: 0, unreadCount: 0, cTime: 0, mTime: 0
                    )
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
                return IMCoreManager.shared.api.querySession(IMCoreManager.shared.uId, sessionId)
            }
        })
    }
    
    func queryLocalSessions(_ count: Int, _ mTime: Int64) -> Observable<Array<Session>> {
        return Observable.create({observer -> Disposable in
            do {
                let sessions = try IMCoreManager.shared.database.sessionDao.querySessions(count, mTime)
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
    
    func queryLocalMessages(_ sessionId: Int64, _ cTime: Int64, _ count: Int) -> Observable<Array<Message>> {
        return Observable.create({observer -> Disposable in
            do {
                let messages = try IMCoreManager.shared.database.messageDao.queryMessageBySidAndCTime(sessionId, cTime, count)
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
    
    func deleteSession(_ sessionList: Array<Session>, _ deleteServer: Bool) -> Observable<Bool> {
        // TODO
        return Observable.just(true)
    }
    
    func onNewMessage(_ msg: Message) {
        msgLock.lock()
        getMsgProcessor(msg.type).received(msg)
        processSessionByMessage(msg)
        msgLock.unlock()
    }
    
    func generateNewMsgId() -> Int64 {
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
        return current * 100 + Int64(self.lastSequence)
    }
    
    func sendMessage(_ body: Codable, _ sessionId: Int64, _ type: Int,
                     _ atUser: String? = nil, _ replyMsgId: Int64? = nil) -> Bool{
        let processor = getMsgProcessor(type)
        return processor.sendMessage(body, sessionId, atUser, replyMsgId)
    }
    
    func sendMessageToServer(_ message: Message) -> Observable<Message> {
        return IMCoreManager.shared.api.sendMessageToServer(msg: message)
    }
    
    func readMessages(_ sessionId: Int64, _ msgIds: [Int64]?) -> Observable<Bool> {
        // TODO
        return Observable.just(true)
    }
    
    func revokeMessage(_ message: Message) -> Observable<Bool> {
        // TODO
        return Observable.just(true)
    }
    
    func reeditMessage(_ message: Message) -> Observable<Bool> {
        // TODO
        return Observable.just(true)
    }
    
    func ackMessageToCache(_ sessionId: Int64, _ msgId: Int64) {
        ackLock.lock()
        if self.needAckDic[sessionId] == nil {
            self.needAckDic[sessionId] = Set()
        }
        self.needAckDic[sessionId]!.insert(msgId)
        ackLock.unlock()
    }
    
    private func ackMessageSuccess(_ sessionId: Int64, _ msgIds: Set<Int64>) {
        ackLock.lock()
        var messageIds = needAckDic[sessionId]
        if messageIds != nil {
            for id in msgIds {
                messageIds!.remove(id)
            }
            needAckDic[sessionId] = messageIds
        }
        ackLock.unlock()
    }

    
    private func ackServerMessage(_ sessionId: Int64, _ msgIds: Set<Int64>) {
        IMCoreManager.shared.api.ackMessages(IMCoreManager.shared.uId, sessionId, msgIds)
            .compose(DefaultRxTransformer.io2Io())
            .subscribe(
                onNext: { success in
                    if success {
                        self.ackMessageSuccess(sessionId, msgIds)
                    }
                },
                onError: { error in
                    DDLogError(error)
                }
            ).disposed(by: disposeBag)
    }
    
    func ackMessagesToServer() {
        ackLock.lock()
        for (k, v) in self.needAckDic {
            if v.count > 0 {
                self.ackServerMessage(k, v)
            }
        }
        ackLock.unlock()
    }
    
    private func deleteServerMessages(_ sessionId: Int64, _ msgIds: Set<Int64>) -> Observable<Bool> {
        return IMCoreManager.shared.api.deleteMessages(IMCoreManager.shared.uId, sessionId, msgIds)
    }

    private func deleteLocalMessages(_ messages: Array<Message>) -> Observable<Bool> {
        return Observable.create({observer -> Disposable in
            do {
                try IMCoreManager.shared.database.messageDao.deleteMessages(messages)
                observer.onNext(true)
            } catch {
                observer.onNext(false)
            }
            observer.onCompleted()
            return Disposables.create()
        })
    }
    
    func deleteMessages(_ sessionId: Int64, _ messages: Array<Message>, _ deleteServer: Bool) -> Observable<Bool> {
        if (deleteServer) {
            var ids = Set<Int64>()
            for message in messages {
                if message.msgId > 0 { // msgId 大于0 才是正确的服务端消息id
                    ids.insert(message.msgId)
                }
            }
            return self.deleteServerMessages(sessionId, ids)
        }
        return self.deleteLocalMessages(messages)
    }
    
    func processSessionByMessage(_ msg: Message) {
        let sessionDao = IMCoreManager.shared.database.sessionDao
        self.getSession(msg.sessionId)
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
    
    func onSignalReceived(_ subType: Int, _ body: String) {
        if subType == 0 {
            do {
                let msgBean = try JSONDecoder().decode(
                    MessageBean.self,
                    from: body.data(using: String.Encoding.utf8)!)
                let msg = msgBean.toMessage()
                onNewMessage(msg)
            } catch {
                DDLogError(error)
            }
        } else {
            DDLogError(String(format: "subType: %d message not support", subType))
        }
    }
    
    
    func cancelAllTasks()   {
        for v in self.processorDic {
            v.value.reset()
        }
    }
}
