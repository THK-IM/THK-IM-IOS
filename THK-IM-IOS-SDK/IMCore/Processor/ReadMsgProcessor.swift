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
                self?.readMessagesToServer()
            })
            .disposed(by: self.disposeBag)
    }
    
    
    override public func messageType() -> Int {
        return MsgType.READ.rawValue
    }
    
    override public func received(_ msg: Message) {
        // 自己发的已读消息，更新rMsgId的消息状态为服务端已读
        if (msg.fromUId == IMCoreManager.shared.uId) {
            if (msg.referMsgId != nil) {
                do {
                    try IMCoreManager.shared.database.messageDao
                        .updateMessageOperationStatus(
                            msg.sessionId,
                            [msg.referMsgId!],
                            MsgOperateStatus.ServerRead.rawValue | MsgOperateStatus.ClientRead.rawValue
                        )
                } catch {
                    DDLogError("updateMessageOperationStatus err: \(error)")
                }
            }
        } else {
            // TODO
            IMCoreManager.shared.getMessageModule().ackMessageToCache(msg)
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
                observer.onNext(msg)
            } catch {
                observer.onError(error)
            }
            observer.onCompleted()
            return Disposables.create()
        }).compose(RxTransformer.shared.io2Io())
            .subscribe(onNext: { [weak self] message in
                IMCoreManager.shared.getMessageModule().processSessionByMessage(message)
                self?.readMessageToCache(message)
                
            }, onError: { error in
                DDLogError("send readMessage error: \(error)")
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

    
    private func readServerMessage(_ sessionId: Int64, _ msgIds: Set<Int64>) {
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
                        DDLogError("ackMessageSuccess error: \(error)")
                    }
                }
            ).disposed(by: disposeBag)
    }
    
    private func readMessagesToServer() {
        readLock.lock()
        for (k, v) in self.needReadDic {
            if v.count > 0 {
                print("ackMessagesToServer \(k) \(v)")
                self.readServerMessage(k, v)
            }
        }
        readLock.unlock()
    }
    
}
