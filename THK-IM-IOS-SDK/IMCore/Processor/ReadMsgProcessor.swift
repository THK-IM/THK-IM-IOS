//
//  ReadMsgProcessor.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/4.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import CocoaLumberjack
import RxSwift
import SwiftEventBus

public class ReadMsgProcessor: BaseMsgProcessor {
    
    private var needReadDic = [Int64: Set<Int64>]()
    private let readLock = NSLock()
    
    override init() {
        super.init()
        Observable<Int>.interval(.seconds(2), scheduler: RxSwift.MainScheduler())
            .asObservable()
            .compose(RxTransformer.shared.io2Io())
            .subscribe(onNext: { [weak self] _ in
                DDLogInfo("readMessagesToServer")
                self?.sendReadMessagesToServer()
            })
            .disposed(by: self.disposeBag)
    }
    
    
    override public func messageType() -> Int {
        return MsgType.READ.rawValue
    }
    
    override public func received(_ msg: Message) {
        if (msg.referMsgId == nil) {
            return
        }
        do {
            DDLogInfo("ReadMsgProcessor received msg \(msg.id) \(msg.fromUId) \(msg.operateStatus)")
            let referMsg = try IMCoreManager.shared.database.messageDao.findMessageByMsgId(msg.referMsgId!, msg.sessionId)
            if (referMsg != nil) {
                DDLogInfo("ReadMsgProcessor received referMsg \(referMsg!.id) \(referMsg!.fromUId) \(referMsg!.operateStatus)")
                if (msg.fromUId == IMCoreManager.shared.uId) {
                    // 自己发的已读消息，更新rMsgId的消息状态为服务端已读
                    referMsg!.operateStatus = MsgOperateStatus.ServerRead.rawValue | 
                                                MsgOperateStatus.ClientRead.rawValue |
                                                MsgOperateStatus.Ack.rawValue
                    referMsg!.mTime = msg.cTime
                    try insertOrUpdateDb(referMsg!, true, false)
                    let session = try IMCoreManager.shared.database.sessionDao.findSessionById(msg.sessionId)
                    if (session != nil) {
                        let count = try IMCoreManager.shared.database.messageDao.getUnReadCount(session!.id)
                        if (session!.unreadCount != count || session!.mTime < msg.mTime) {
                            session!.unreadCount = count
                            session!.mTime = IMCoreManager.shared.getCommonModule().getSeverTime()
                            try IMCoreManager.shared.database.sessionDao.updateSessions(session!)
                            SwiftEventBus.post(IMEvent.SessionUpdate.rawValue, sender: session)
                        }
                    }
                } else {
                    // 别人发给自己的已读消息
                    if (referMsg!.rUsers != nil) {
                        referMsg!.rUsers = "\(referMsg!.rUsers!)#\(msg.fromUId)"
                    } else {
                        referMsg!.rUsers = "\(msg.fromUId)"
                    }
                    referMsg!.mTime = msg.cTime
                    try insertOrUpdateDb(referMsg!, true, false)
                    // 状态操作消息对用户不可见，默认状态即位本身已读
                    msg.operateStatus = MsgOperateStatus.ClientRead.rawValue | MsgOperateStatus.ServerRead.rawValue
                    // 已读消息入库，并ack
                    try insertOrUpdateDb(referMsg!, false, false)
                    if msg.operateStatus & MsgOperateStatus.Ack.rawValue == 0 {
                        IMCoreManager.shared.getMessageModule().ackMessageToCache(msg)
                    }
                }
            }
        } catch {
            DDLogError("ReadMsgProcessor received err: \(error)")
        }
        
        
    }
    
    override public func send(_ msg: Message, resend: Bool = false) {
        if (msg.referMsgId == nil || msg.referMsgId! < 0) {
            return
        }
        Observable.create({observer -> Disposable in
            do {
                try IMCoreManager.shared.database.messageDao
                    .updateMessageOperationStatus(
                        msg.sessionId,
                        [msg.referMsgId!],
                        MsgOperateStatus.ClientRead.rawValue | MsgOperateStatus.Ack.rawValue
                    )
                let session = try IMCoreManager.shared.database.sessionDao.findSessionById(msg.sessionId)
                if (session != nil) {
                    let count = try IMCoreManager.shared.database.messageDao.getUnReadCount(session!.id)
                    if (session!.unreadCount != count || session!.mTime < msg.mTime) {
                        session!.unreadCount = count
                        session!.mTime = msg.mTime
                        try IMCoreManager.shared.database.sessionDao.updateSessions(session!)
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
            .subscribe(onNext: { [weak self] message in
                self?.readMessageToCache(message)
            }, onError: { error in
                DDLogError("ReadMsgProcessor send error: \(error)")
            }
        ).disposed(by: self.disposeBag)
    }
    
    private func readMessageToCache(_ msg: Message) {
        readLock.lock()
        if self.needReadDic[msg.sessionId] == nil {
            self.needReadDic[msg.sessionId] = Set()
        }
        if (msg.referMsgId != nil) {
            self.needReadDic[msg.sessionId]!.insert(msg.referMsgId!)
        }
        readLock.unlock()
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
                    DDLogError(error)
                },
                onCompleted: {
                    do {
                        try IMCoreManager.shared.database.messageDao.updateMessageOperationStatus(
                                sessionId,
                                msgIds.compactMap({$0}),
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
    
}