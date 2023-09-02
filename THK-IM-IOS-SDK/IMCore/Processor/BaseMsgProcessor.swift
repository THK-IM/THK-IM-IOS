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

public class BaseMsgProcessor {
    
    private var disposeBag = DisposeBag()
    
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
                // 数据库存在，更新本地数据库数据
                if dbMsg!.sendStatus != MsgSendStatus.Success.rawValue {
                    msg.data = dbMsg!.data
                    msg.operateStatus = dbMsg!.operateStatus
                    msg.msgId = dbMsg!.msgId
                    msg.sendStatus = MsgSendStatus.Success.rawValue
                    try insertOrUpdateDb(msg)
                }
            }
            IMCoreManager.shared.getMessageModule().ackMessageToCache(msg.sessionId, msg.msgId)
        } catch let error {
            DDLogError("Received NewMsg \(error)")
        }
    }
    
    // 图片压缩/视频抽帧等操作二次处理
    open func reprocessingObservable(_ message: Message) -> Observable<Message>? {
        return nil
    }
    
    // 上传
    open func uploadObservable(_ message: Message) -> Observable<Message>? {
        return nil
    }
    
    open func buildSendMsg(_ c :Codable, _ sessionId: Int64, _ atUIdStr: String? = nil, _ rMsgId: Int64? = nil) throws -> Message {
        var body = ""
        if (c is String) {
            body = c as! String
        } else {
            let data = try JSONEncoder().encode(c)
            guard let jsonBody = String(data: data, encoding: .utf8) else {
                throw CocoaError.init(.coderInvalidValue)
            }
            body = jsonBody
        }
        let clientId = IMCoreManager.shared.getMessageModule().generateNewMsgId()
        let now = IMCoreManager.shared.getCommonModule().getSeverTime()
        let msg = Message(
            id: clientId, sessionId: sessionId, fromUId: IMCoreManager.shared.uId, msgId: -clientId, type: messageType(),
            content: body, sendStatus: MsgSendStatus.Init.rawValue, operateStatus: MsgOperateStatus.Init.rawValue,
            cTime: now, mTime: now
        )
        return msg
    }
    
    open func sendMessage(_ c: Codable, _ sessionId: Int64, _ atUsers: String? = nil, _ rMsgId: Int64? = nil) -> Bool {
        do {
            let originMsg = try self.buildSendMsg(c, sessionId, atUsers, rMsgId)
            self.resend(originMsg)
        } catch {
            DDLogError(error)
            return false
        }
        return true
    }
    
    open func resend(_ msg: Message) {
        var originMsg = msg
        Observable.just(msg)
            .flatMap({ (message) -> Observable<Message> in
                // 消息二次处理
                let reprocessingObservable = self.reprocessingObservable(message)
                if reprocessingObservable != nil {
                    return reprocessingObservable!
                } else {
                    return Observable.just(message)
                }
            })
            .flatMap({ (message) -> Observable<Message> in
                // 消息内容上传
                message.sendStatus = MsgSendStatus.Uploading.rawValue
                do {
                    try self.insertOrUpdateDb(message)
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
                // 消息发送到服务端
                message.sendStatus = MsgSendStatus.Sending.rawValue
                try self.insertOrUpdateDb(message, false)
                originMsg = msg // 防止失败时缺失数据
                return IMCoreManager.shared.api.sendMessageToServer(msg:message)
            })
            .compose(DefaultRxTransformer.io2Io())
            .subscribe(onNext: { msg in
                do {
                    try self.insertOrUpdateDb(msg)
                } catch let error {
                    DDLogError(error)
                }
            }, onError: { error in
                DDLogError(error)
                originMsg.sendStatus = MsgSendStatus.Failed.rawValue
                do {
                    try self.updateFailedMsgStatus(msg)
                } catch let error {
                    DDLogError(error)
                }
            })
            .disposed(by: disposeBag)
    }
    
    open func messageType() -> Int {
        return 0
    }
    
    /**
     * 【插入或更新消息状态】
     */
    open func insertOrUpdateDb(_ msg: Message, _ notify: Bool = true) throws {
        try IMCoreManager.shared.database.messageDao.insertMessages(msg)
        if notify {
            SwiftEventBus.post(IMEvent.MsgNew.rawValue, sender: msg)
        }
        if msg.sendStatus == MsgSendStatus.Uploading.rawValue
            || msg.sendStatus == MsgSendStatus.Success.rawValue
            || msg.sendStatus == MsgSendStatus.Failed.rawValue {
            IMCoreManager.shared.getMessageModule().processSessionByMessage(msg)
        }
    }
    
    /**
     * 【更新消息状态】用于在调用api发送消息失败时更新本地数据库消息状态
     */
    open func updateFailedMsgStatus(_ msg: Message) throws {
        try IMCoreManager.shared.database.messageDao.updateSendStatus(
            msg.sessionId, msg.id, msg.fromUId, MsgSendStatus.Failed.rawValue
        )
        SwiftEventBus.post(IMEvent.MsgNew.rawValue, sender: msg)
        if msg.sendStatus == MsgSendStatus.Uploading.rawValue
            || msg.sendStatus == MsgSendStatus.Success.rawValue
            || msg.sendStatus == MsgSendStatus.Failed.rawValue {
            IMCoreManager.shared.getMessageModule().processSessionByMessage(msg)
        }
    }
    
    /**
     * 消息是否在界面上显示，撤回/已读/已接受等状态消息不显示
     */
    open func isShow(msg: Message)-> Bool {
        // type小于0是操作类型消息
        return msg.type > 0
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
        return isShow(msg: msg)
    }
    
    /**
     * 该消息在session上的描述
     */
    open func getSessionDesc(msg: Message) -> String {
        return msg.content
    }
    
    open func reset() {
        // 取消监听执行中的任务
        self.disposeBag = DisposeBag()
    }
    
}
