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
        return IMManager.shared.getMessageModule()
    }
    
    /**
     * 处理收到的消息入库
     */
    open func received(_ msg: Message){
        do {
            let dbMsg = try IMManager.shared.database.messageDao.findMessage(msg.id, msg.fUId)
            if (dbMsg == nil) {
                if (msg.fUId == IMManager.shared.uId) {
                    msg.status = MsgStatus.AlreadyReadInServer.rawValue
                }
                try IMManager.shared.database.messageDao.insertMessages(msg)
                SwiftEventBus.post(IMEvent.MsgNew.rawValue, sender: msg)
            } else {
                // 数据库存在，只更新消息状态
                if msg.status >= dbMsg!.status {
                    try updateMsgStatus(msg)
                }
            }
            IMManager.shared.getMessageModule().ackMessage(msg.sid, msg.msgId)
        } catch let error {
            DDLogError(error)
        }
    }
    
    open func uploadObservable(_ entity: Message) -> Observable<Message>? {
        return nil
    }
    
    open func buildSendMsg(_ body:String, _ sid: Int64, _ atUsers: String? = nil, _ rMsgId: Int64? = nil) -> Message {
        let clientId = IMManager.shared.getMessageModule().newMsgId()
        let now = IMManager.shared.getCommonModule().getSeverTime()
        let msg = Message()
        msg.id = clientId
        msg.fUId = IMManager.shared.uId
        msg.sid = sid
        msg.msgId = -clientId
        msg.type =  messageType()
        msg.content = body
        msg.status = MsgStatus.Init.rawValue
        msg.cTime = now
        msg.mTime = now
        return msg
    }
    
    open func sendMessage(_ body: String, _ sid: Int64, _ atUsers: String? = nil, _ rMsgId: Int64? = nil, _ params: Dictionary<String, Any>? = nil) {
        let msg = self.buildSendMsg(body, sid, atUsers, rMsgId)
        Observable.create({observer -> Disposable in
            do {
                msg.status = MsgStatus.Sending.rawValue
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
        .flatMap({ (message) -> Observable<MessageBean> in
            let bean = self.entity2MsgBean(msg: message)
            return self.getMessageModule().sendMessageToServer(bean)
        })
        .compose(DefaultRxTransformer.io2Io())
        .subscribe(onNext: { bean in
            msg.msgId = bean.msgId
            msg.status = MsgStatus.SendOrRSuccess.rawValue
            msg.cTime = bean.cTime
            do {
                try self.updateMsgStatus(msg)
            } catch let error {
                DDLogError(error)
            }
        }, onError: { error in
            DDLogError(error)
            msg.status = MsgStatus.SendFailed.rawValue
            do {
                try self.updateMsgStatus(msg)
            } catch let error {
                DDLogError(error)
            }
        })
        .disposed(by: disposeBag)
    }
    
    open func resend(_ msg: Message) {
        Observable.just(msg)
            .flatMap({ (message) -> Observable<Message> in
                message.status = MsgStatus.Sending.rawValue
                do {
                    try self.updateMsgStatus(message)
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
            .flatMap({ (message) -> Observable<MessageBean> in
                let bean = self.entity2MsgBean(msg: message)
                return self.getMessageModule().sendMessageToServer(bean)
            })
            .compose(DefaultRxTransformer.io2Io())
            .subscribe(onNext: { bean in
                msg.msgId = bean.msgId
                msg.status = MsgStatus.AlreadyReadInServer.rawValue
                msg.cTime = bean.cTime
                do {
                    try self.updateMsgStatus(msg)
                } catch let error {
                    DDLogError(error)
                }
            }, onError: { error in
                DDLogError(error)
                msg.status = MsgStatus.SendFailed.rawValue
                do {
                    try self.updateMsgStatus(msg)
                } catch let error {
                    DDLogError(error)
                }
            })
            .disposed(by: disposeBag)
    }
    
    open func messageType() -> Int {
        return 0
    }
    
    open func msgBean2Entity(bean: MessageBean) -> Message {
        return bean.toMessage()
    }
    
    /**
     * 本地数据entity转换为与服务器交互的bean
     */
    open func entity2MsgBean(msg: Message) -> MessageBean {
        return MessageBean(msg: msg)
    }
    
    open func insertDb(_ msg: Message) throws {
        DDLogDebug("BaseMsgProcessor insertDb ")
        try IMManager.shared.database.messageDao.insertMessages(msg)
        SwiftEventBus.post(IMEvent.MsgNew.rawValue, sender: msg)
        IMManager.shared.getMessageModule().processSessionByMessage(msg)
    }
    
    
//    open func updateDb(_ msg: Message) throws {
//        DDLogDebug("BaseMsgProcessor updateDb ")
//        try IMManager.shared.database.messageDao.updateMessages(msg)
//    }
    
    open func updateMsgContent(_ msg: Message, _ sendNotify: Bool = false) throws {
        DDLogDebug("BaseMsgProcessor updateMsgContent \(sendNotify), msg id: \(msg.id), status: \(msg.status)")
        let msgDao = IMManager.shared.database.messageDao
        try msgDao.updateMessageContent(msg.id, msg.fUId, msg.content)
        if (sendNotify == true) {
            SwiftEventBus.post(IMEvent.MsgUpdate.rawValue, sender: msg)
        }
    }
    
    open func updateMsgStatus(_ msg: Message) throws {
        DDLogDebug("BaseMsgProcessor updateMsgStatus: \(msg.status), id: \(msg.id)")
        let msgDao = IMManager.shared.database.messageDao
        try msgDao.updateMessageStatus(msg.id, msg.fUId, msg.status, msg.msgId, msg.cTime)
        SwiftEventBus.post(IMEvent.MsgUpdate.rawValue, sender: msg)
        IMManager.shared.getMessageModule().processSessionByMessage(msg)
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
