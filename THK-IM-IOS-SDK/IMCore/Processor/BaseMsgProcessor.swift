//
//  BaseMsgProcessor.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/13.
//

import Foundation
import RxSwift
import CocoaLumberjack
import SwiftEventBus

class BaseMsgProcessor {
    
    private let disposeBag = DisposeBag()
    
    func getMessageModule() -> MessageModule {
        return IMCoreManager.shared.getMessageModule()
    }
    
    /**
     * 处理收到的消息入库
     */
    open func received(_ msg: Message){
        do {
            let dbMsg = try IMCoreManager.shared.database.messageDao.findMessage(msg.id, msg.sessionId, msg.fromUId)
            if (dbMsg == nil) {
                // 数据库不存在
                if (msg.fromUId == IMCoreManager.shared.uId) {
                    // 如果发件人为自己，插入前补充消息状态为已接受并已读
                    msg.operateStatus = msg.operateStatus |
                        MsgOperateStatus.Ack.rawValue |
                        MsgOperateStatus.ClientRead.rawValue |
                        MsgOperateStatus.ServerRead.rawValue
                    msg.sendStatus = MsgSendStatus.Success.rawValue
                }
                try IMCoreManager.shared.database.messageDao.insertMessages(msg)
                SwiftEventBus.post(IMEvent.MsgNew.rawValue, sender: msg)
            } else {
                // 数据库存在，只更新消息状态
                msg.sendStatus = MsgSendStatus.Success.rawValue
                try updateMsgSendStatus(msg)
            }
            IMCoreManager.shared.getMessageModule().ackMessageToCache(msg.sessionId, msg.msgId)
        } catch let error {
            DDLogError("Received New Msg \(error)")
        }
    }
    
    open func uploadObservable(_ entity: Message) -> Observable<Message>? {
        return nil
    }
    
    open func buildSendMsg(_ body:String, _ sid: Int64, _ atUsers: String? = nil, _ rMsgId: Int64? = nil) -> Message {
        let clientId = IMCoreManager.shared.getMessageModule().generateNewMsgId()
        let now = IMCoreManager.shared.getCommonModule().getSeverTime()
        let msg = Message(
            id: clientId, sessionId: sid, fromUId: IMCoreManager.shared.uId, msgId: -clientId, type: messageType(),
            content: body, sendStatus: MsgSendStatus.Init.rawValue, operateStatus: MsgOperateStatus.Init.rawValue,
            cTime: now, mTime: now
        )
        return msg
    }
    
    open func sendMessage(_ body: String, _ sid: Int64, _ atUsers: String? = nil, _ rMsgId: Int64? = nil) {
        let msg = self.buildSendMsg(body, sid, atUsers, rMsgId)
        Observable.create({observer -> Disposable in
            do {
                msg.sendStatus = MsgSendStatus.Sending.rawValue
                try self.insertDb(msg)
                observer.onNext(msg)
            } catch let error {
                observer.onError(error)
            }
            observer.onCompleted()
            return Disposables.create()
        })
        .flatMap({ (message) -> Observable<Message> in
            let uploadObservable = self.uploadObservable(message)
            if uploadObservable != nil {
                return uploadObservable!
            } else {
                return Observable.just(message)
            }
        })
        .flatMap({ (message) -> Observable<Message> in
            return IMCoreManager.shared.api.sendMessageToServer(msg:message)
        })
        .compose(DefaultRxTransformer.io2Io())
        .subscribe(onNext: { bean in
            do {
                try self.updateMsgSendStatus(msg)
            } catch let error {
                DDLogError(error)
            }
        }, onError: { error in
            DDLogError(error)
            msg.sendStatus = MsgSendStatus.Success.rawValue
            do {
                try self.updateMsgSendStatus(msg)
            } catch let error {
                DDLogError(error)
            }
        })
        .disposed(by: disposeBag)
    }
    
    open func resend(_ msg: Message) {
        Observable.just(msg)
            .flatMap({ (message) -> Observable<Message> in
                message.sendStatus = MsgSendStatus.Sending.rawValue
                do {
                    try self.updateMsgSendStatus(message)
                } catch let error {
                    return Observable.error(error)
                }
                let uploadObservable = self.uploadObservable(message)
                if uploadObservable != nil {
                    return uploadObservable!
                } else {
                    return Observable.just(message)
                }
            })
            .flatMap({ (message) -> Observable<Message> in
                return IMCoreManager.shared.api.sendMessageToServer(msg:message)
            })
            .compose(DefaultRxTransformer.io2Io())
            .subscribe(onNext: { msg in
                do {
                    try self.updateMsgSendStatus(msg)
                } catch let error {
                    DDLogError(error)
                }
            }, onError: { error in
                DDLogError(error)
                msg.sendStatus = MsgSendStatus.Failed.rawValue
                do {
                    try self.updateMsgSendStatus(msg)
                } catch let error {
                    DDLogError(error)
                }
            })
            .disposed(by: disposeBag)
    }
    
    open func messageType() -> Int {
        return 0
    }
    
    open func insertDb(_ msg: Message) throws {
        try IMCoreManager.shared.database.messageDao.insertMessages(msg)
        SwiftEventBus.post(IMEvent.MsgNew.rawValue, sender: msg)
        IMCoreManager.shared.getMessageModule().processSessionByMessage(msg)
    }
    
    open func updateMsgContent(_ msg: Message, _ sendNotify: Bool = false) throws {
        let msgDao = IMCoreManager.shared.database.messageDao
        try msgDao.updateMessageContent(msg.id, msg.sessionId, msg.fromUId, msg.content)
        if (sendNotify == true) {
            SwiftEventBus.post(IMEvent.MsgUpdate.rawValue, sender: msg)
        }
    }
    
    open func updateMsgSendStatus(_ msg: Message) throws {
        let msgDao = IMCoreManager.shared.database.messageDao
        try msgDao.updateSendStatus(msg.sessionId, msg.id, msg.fromUId, msg.sendStatus)
        SwiftEventBus.post(IMEvent.MsgUpdate.rawValue, sender: msg)
        IMCoreManager.shared.getMessageModule().processSessionByMessage(msg)
    }
    
    /**
     * 消息是否在界面上显示，撤回/已读/已接受等状态消息不显示
     */
    open func isShow(msg: Message)-> Bool {
        return true
    }
    
    /**
     * 消息是否可以删除
     */
    open func canDeleted(msg: Message)-> Bool {
        return true
    }
    
    /**
     * 消息是否可以撤回
     */
    open func canRevoke(msg: Message)-> Bool {
        return false
    }
    
    /**
     * 该消息在session上的描述
     */
    open func getSessionDesc(msg: Message) -> String {
        return msg.content
    }
    
}
