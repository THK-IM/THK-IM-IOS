//
//  BaseMsgProcessor.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/13.
//

import Foundation
import RxSwift
import CocoaLumberjack

open class BaseMsgProcessor {
    
    open var disposeBag = DisposeBag()
    open var downloadUrls = [String]()
    
    func getMessageModule() -> MessageModule {
        return IMCoreManager.shared.getMessageModule()
    }
    
    /**
     * 处理收到的消息入库
     */
    open func received(_ msg: Message){
        do {
            let dbMsg = try IMCoreManager.shared.database.messageDao.findMessageById(msg.id, msg.fromUId, msg.sessionId)
            if (dbMsg == nil) {
                // 数据库不存在
                if (msg.fromUId == IMCoreManager.shared.uId) {
                    // 如果发件人为自己，插入前补充消息状态为已接受并已读
                    msg.operateStatus = msg.operateStatus |
                        MsgOperateStatus.Ack.rawValue |
                        MsgOperateStatus.ClientRead.rawValue |
                        MsgOperateStatus.ServerRead.rawValue
                }
                try self.insertOrUpdateDb(msg)
                if (msg.operateStatus & MsgOperateStatus.Ack.rawValue == 0 && msg.fromUId != IMCoreManager.shared.uId) {
                    IMCoreManager.shared.getMessageModule().ackMessageToCache(msg)
                }
            } else {
                // 数据库存在，更新本地数据库数据
                if dbMsg!.sendStatus != MsgSendStatus.Success.rawValue {
                    msg.data = dbMsg!.data
                    if (msg.fromUId == IMCoreManager.shared.uId) {
                        // 如果发件人为自己，插入前补充消息状态为已接受并已读
                        msg.operateStatus = msg.operateStatus |
                            MsgOperateStatus.Ack.rawValue |
                            MsgOperateStatus.ClientRead.rawValue |
                            MsgOperateStatus.ServerRead.rawValue
                    }
                    msg.sendStatus = MsgSendStatus.Success.rawValue
                    try insertOrUpdateDb(msg)
                }
                if (msg.operateStatus & MsgOperateStatus.Ack.rawValue == 0 && msg.fromUId != IMCoreManager.shared.uId) {
                    IMCoreManager.shared.getMessageModule().ackMessageToCache(msg)
                }
            }
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
    
    /**
     * 消息内容下载
     */
    open func downloadMsgContent(_ message: Message, resourceType: String) -> Bool {
        return true
    }
    
    open func buildSendMsg(_ body :Codable, _ sessionId: Int64, _ atUIdStr: String? = nil, _ rMsgId: Int64? = nil) throws -> Message {
        var content: String? = nil
        var data = ""
        if (body is String) {
            content = body as! String?
        } else {
            let jsonData = try JSONEncoder().encode(body)
            guard let jsonBody = String(data: jsonData, encoding: .utf8) else {
                throw CocoaError.init(.coderInvalidValue)
            }
            data = jsonBody
        }
        let clientId = IMCoreManager.shared.getMessageModule().generateNewMsgId()
        let now = IMCoreManager.shared.getCommonModule().getSeverTime()
        let operateStatus = MsgOperateStatus.Ack.rawValue | MsgOperateStatus.ClientRead.rawValue | MsgOperateStatus.ServerRead.rawValue
        // tips：msgId初始值给-clientId,发送成功后更新为服务端返回的msgId
        let msg = Message(
            id: clientId, 
            sessionId: sessionId,
            fromUId: IMCoreManager.shared.uId,
            msgId: -clientId,
            type: messageType(),
            content: content, 
            data: data,
            sendStatus: MsgSendStatus.Init.rawValue,
            operateStatus: operateStatus,
            rUsers: nil,
            referMsgId: rMsgId,
            atUsers: atUIdStr,
            cTime: now,
            mTime: now
        )
        return msg
    }
    
    /**
     * 发送消息,逻辑流程:
     * 1、写入数据库,
     * 2、消息处理，图片压缩/视频抽帧等
     * 3、文件上传
     * 4、调用api发送消息到服务器
     */
    open func sendMessage(_ body: Codable, _ sessionId: Int64, _ atUsers: String? = nil, _ rMsgId: Int64? = nil) -> Bool {
        do {
            let originMsg = try self.buildSendMsg(body, sessionId, atUsers, rMsgId)
            self.send(originMsg)
        } catch {
            DDLogError(error)
            return false
        }
        return true
    }
    
    open func resend(_ msg: Message) {
        send(msg, resend: true)
    }
    
    open func send(_ msg: Message, resend: Bool = false) {
        var originMsg = msg
        Observable.just(msg)
            .flatMap({ (message) -> Observable<Message> in
                if (!resend) {
                    do {
                        try self.insertOrUpdateDb(message)
                    } catch let error {
                        return Observable.error(error)
                    }
                }
                // 消息二次处理
                let reprocessingObservable = self.reprocessingObservable(message)
                if reprocessingObservable != nil {
                    return reprocessingObservable!
                } else {
                    return Observable.just(message)
                }
            })
            .flatMap({ (message) -> Observable<Message> in
                originMsg = message // 防止失败时缺失数据
                let uploadObservable = self.uploadObservable(message)
                if uploadObservable != nil {
                    // 消息内容上传
                    message.sendStatus = MsgSendStatus.Uploading.rawValue
                    do {
                        try self.insertOrUpdateDb(message)
                    } catch {
                        return Observable.error(error)
                    }
                    return uploadObservable!
                } else {
                    return Observable.just(message)
                }
            })
            .flatMap({ (message) -> Observable<Message> in
                originMsg = message // 防止失败时缺失数据
                // 消息发送到服务端
                message.sendStatus = MsgSendStatus.Sending.rawValue
                try self.insertOrUpdateDb(message, false)
                return IMCoreManager.shared.api.sendMessageToServer(msg:message)
            })
            .compose(RxTransformer.shared.io2Io())
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
    open func insertOrUpdateDb(_ msg: Message, _ notify: Bool = true, _ notifySession: Bool = true) throws {
        try IMCoreManager.shared.database.messageDao.insertOrReplaceMessages([msg])
        if notify {
            SwiftEventBus.post(IMEvent.MsgNew.rawValue, sender: msg)
        }
        if notify && notifySession {
            if msg.sendStatus == MsgSendStatus.Uploading.rawValue
                || msg.sendStatus == MsgSendStatus.Success.rawValue
                || msg.sendStatus == MsgSendStatus.Failed.rawValue {
                IMCoreManager.shared.getMessageModule().processSessionByMessage(msg)
            }
        }
    }
    
    /**
     * 【更新消息状态】用于在调用api发送消息失败时更新本地数据库消息状态
     */
    open func updateFailedMsgStatus(_ msg: Message, _ notify: Bool = true) throws {
        try IMCoreManager.shared.database.messageDao.updateSendStatus(
            msg.sessionId, msg.id, msg.fromUId, MsgSendStatus.Failed.rawValue
        )
        if (notify) {
            SwiftEventBus.post(IMEvent.MsgUpdate.rawValue, sender: msg)
            if msg.sendStatus == MsgSendStatus.Uploading.rawValue
                || msg.sendStatus == MsgSendStatus.Success.rawValue
                || msg.sendStatus == MsgSendStatus.Failed.rawValue {
                IMCoreManager.shared.getMessageModule().processSessionByMessage(msg)
            }
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
        if (msg.content != nil) {
            return msg.content!
        }
        return ""
    }
    
    open func reset() {
        // 取消监听执行中的任务
        self.disposeBag = DisposeBag()
    }
    
}
