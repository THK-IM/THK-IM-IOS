//
//  IMReadMsgProcessor.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/4.
//  Copyright © 2023 THK. All rights reserved.
//

import CocoaLumberjack
import Foundation
import RxSwift

public class IMReadMsgProcessor: IMBaseMsgProcessor {

    private var needReadDic = [Int64: Set<Int64>]()
    private let readLock = NSLock()
    private var lastSendReadMessageTime: Int64 = 0
    private let publishSubject = PublishSubject<Int>()

    override init() {
        super.init()
        self.initReadMessagePublishSubject()
    }

    private func initReadMessagePublishSubject() {
        let scheduler = RxSwift.ConcurrentDispatchQueueScheduler(queue: DispatchQueue.global())
        publishSubject.debounce(self.sendInterval(), scheduler: scheduler)
            .subscribe(onNext: { [weak self] _ in
                self?.sendReadMessagesToServer()
            }).disposed(by: self.disposeBag)
    }

    open func sendInterval() -> RxTimeInterval {
        return RxTimeInterval.seconds(2)
    }

    override public func messageType() -> Int {
        return MsgType.Read.rawValue
    }

    override public func received(_ msg: Message) {
        if msg.referMsgId == nil {
            return
        }
        do {
            let dbMsg = try IMCoreManager.shared.database.messageDao().findById(
                msg.id, msg.fromUId, msg.sessionId)
            if dbMsg != nil {
                return
            }
            let referMsg = try IMCoreManager.shared.database.messageDao().findByMsgId(
                msg.referMsgId!, msg.sessionId)
            if referMsg != nil {
                referMsg!.operateStatus =
                    referMsg!.operateStatus | MsgOperateStatus.ServerRead.rawValue
                    | MsgOperateStatus.ClientRead.rawValue | MsgOperateStatus.Ack.rawValue
                if msg.fromUId == IMCoreManager.shared.uId {
                    // 自己发的已读消息，更新rMsgId的消息状态为服务端已读
                    try insertOrUpdateDb(referMsg!, true, false)
                    let session = try IMCoreManager.shared.database.sessionDao().findById(
                        msg.sessionId)
                    if session != nil {
                        let count = try IMCoreManager.shared.database.messageDao().getUnReadCount(
                            session!.id)
                        if session!.unreadCount != count {
                            session!.unreadCount = count
                            try IMCoreManager.shared.database.sessionDao().update([session!])
                            SwiftEventBus.post(IMEvent.SessionUpdate.rawValue, sender: session)
                        }
                    }
                } else {
                    // 别人发给自己的已读消息
                    if referMsg!.rUsers != nil {
                        referMsg!.rUsers = "\(referMsg!.rUsers!)#\(msg.fromUId)"
                    } else {
                        referMsg!.rUsers = "\(msg.fromUId)"
                    }
                    try insertOrUpdateDb(referMsg!, true, false)
                    if msg.operateStatus & MsgOperateStatus.Ack.rawValue == 0 {
                        IMCoreManager.shared.messageModule.ackMessageToCache(msg)
                    }
                }
            }
        } catch {
            DDLogError("ReadMsgProcessor received err: \(error)")
        }

    }

    override public func send(
        _ msg: Message, _ resend: Bool = false, _ sendResult: IMSendMsgResult? = nil
    ) {
        if msg.referMsgId == nil || msg.referMsgId! < 0 {
            return
        }
        Observable.create({ observer -> Disposable in
            do {
                try IMCoreManager.shared.database.messageDao()
                    .updateOperationStatus(
                        msg.sessionId,
                        [msg.referMsgId!],
                        MsgOperateStatus.ClientRead.rawValue | MsgOperateStatus.Ack.rawValue
                    )
                let session = try IMCoreManager.shared.database.sessionDao().findById(msg.sessionId)
                if session != nil {
                    let count = try IMCoreManager.shared.database.messageDao().getUnReadCount(
                        session!.id)
                    if session!.unreadCount != count {
                        session!.unreadCount = count
                        try IMCoreManager.shared.database.sessionDao().update([session!])
                        SwiftEventBus.post(IMEvent.SessionUpdate.rawValue, sender: session)
                    }
                }
                observer.onNext(msg)
            } catch {
                observer.onError(error)
            }
            observer.onCompleted()
            return Disposables.create()
        }).compose(RxTransformer.shared.io2Io())
            .subscribe(
                onNext: { [weak self] message in
                    self?.readMessageToCache(message)
                },
                onError: { error in
                    DDLogError("ReadMsgProcessor send error: \(error)")
                }
            ).disposed(by: self.disposeBag)
    }

    private func readMessageToCache(_ msg: Message) {
        readLock.lock()
        if self.needReadDic[msg.sessionId] == nil {
            self.needReadDic[msg.sessionId] = Set()
        }
        if msg.referMsgId != nil {
            self.needReadDic[msg.sessionId]!.insert(msg.referMsgId!)
        }
        readLock.unlock()
        publishSubject.onNext(0)
    }

    private func readMessageSuccess(_ sessionId: Int64, _ msgIds: Set<Int64>) {
        readLock.lock()
        var messageIds = needReadDic[sessionId]
        if messageIds != nil {
            for id in msgIds {
                messageIds!.remove(id)
            }
            needReadDic[sessionId] = messageIds
        }
        readLock.unlock()
    }

    private func sendReadMessages(_ sessionId: Int64, _ msgIds: Set<Int64>) {
        IMCoreManager.shared.api.readMessages(IMCoreManager.shared.uId, sessionId, msgIds)
            .compose(RxTransformer.shared.io2Io())
            .subscribe(
                onError: { error in
                    DDLogError("\(error)")
                },
                onCompleted: {
                    do {
                        try IMCoreManager.shared.database.messageDao().updateOperationStatus(
                            sessionId,
                            msgIds.compactMap({ $0 }),
                            MsgOperateStatus.ServerRead.rawValue
                        )
                        self.readMessageSuccess(sessionId, msgIds)
                    } catch {
                        DDLogError("ReadMsgProcessor sendReadMessages error: \(error)")
                    }
                }
            ).disposed(by: disposeBag)
    }

    private func sendReadMessagesToServer() {
        readLock.lock()
        for (k, v) in self.needReadDic {
            if v.count > 0 {
                DDLogDebug("ReadMsgProcessor sendReadMessagesToServer \(k) \(v)")
                self.sendReadMessages(k, v)
            }
        }
        readLock.unlock()
    }

    private func clearReadMessagesCache() {
        readLock.lock()
        self.needReadDic.removeAll()
        readLock.unlock()
    }

    override public func needReprocess(msg: Message) -> Bool {
        return true
    }

    override open func msgDesc(msg: Message) -> String {
        return ResourceUtils.loadString("im_msg_desc_read", comment: "")
    }

    override public func reset() {
        super.reset()
        self.clearReadMessagesCache()
        self.initReadMessagePublishSubject()
    }

}
