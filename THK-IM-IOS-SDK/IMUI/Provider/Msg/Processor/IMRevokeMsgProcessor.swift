//
//  IMRevokeMsgProcessor.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/4.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import RxSwift
import CocoaLumberjack

public class IMRevokeMsgProcessor: IMBaseMsgProcessor {
    
    override public func messageType() -> Int {
        return MsgType.Revoke.rawValue
    }
    
    override public func send(_ msg: Message, _ resend: Bool = false, _ sendResult: IMSendMsgResult? = nil) {
        if (msg.fromUId != IMCoreManager.shared.uId) {
            sendResult?(msg, CodeMessageError.Unknown)
            return
        }
        IMCoreManager.shared.api.revokeMessage(msg.fromUId, msg.sessionId, msg.msgId)
            .compose(RxTransformer.shared.io2Io())
            .subscribe(onError: { err in
                sendResult?(msg, err)
            }, onCompleted: {
                sendResult?(msg, nil)
            }).disposed(by: self.disposeBag)
    }
    
    override public func received(_ msg: Message) {
        getIMRevokeMsg(msg: msg)
            .compose(RxTransformer.shared.io2Io())
            .subscribe(onNext: { newMsg in
                if (msg.operateStatus & MsgOperateStatus.Ack.rawValue == 0 && msg.fromUId != IMCoreManager.shared.uId) {
                    IMCoreManager.shared.messageModule.ackMessageToCache(msg)
                }
            }).disposed(by: self.disposeBag)
    }
    
    open func getNickname(msg: Message) -> Observable<String> {
        if msg.fromUId == IMCoreManager.shared.uId {
            return Observable.just("你")
        } else {
            return IMCoreManager.shared.userModule.queryUser(id: msg.fromUId)
                .flatMap { info in
                    return Observable.just(info.nickname)
                }
        }
    }
    
    open func getIMRevokeMsg(msg: Message) -> Observable<Message> {
        return getNickname(msg: msg).flatMap { nickname in
            let data = IMRevokeMsgData(nick: nickname)
            var existed = false
            if (msg.referMsgId != nil) {
                let dbMsg = try IMCoreManager.shared.database.messageDao()
                    .findByMsgId(msg.referMsgId!, msg.sessionId)
                if (dbMsg != nil) {
                    existed = true
                    try IMCoreManager.shared.database.messageDao().delete([dbMsg!])
                    SwiftEventBus.post(IMEvent.MsgDelete.rawValue, sender: dbMsg)
                    if (dbMsg?.fromUId == IMCoreManager.shared.uId) {
                        data.content = dbMsg!.content
                        data.data = dbMsg!.data
                        data.type = dbMsg!.type
                    }
                }
            }
            let revokeData = try JSONEncoder().encode(data)
            msg.operateStatus = MsgOperateStatus.ClientRead.rawValue | MsgOperateStatus.ServerRead.rawValue
            msg.sendStatus = MsgSendStatus.Success.rawValue
            msg.data = String(data: revokeData, encoding: .utf8)
            if (existed) {
                try IMCoreManager.shared.database.messageDao().insertOrIgnore([msg])
                SwiftEventBus.post(IMEvent.MsgNew.rawValue, sender: msg)
                IMCoreManager.shared.messageModule.processSessionByMessage(msg, false)
            }
            return Observable.just(msg)
        }
    }
    
    override public func needReprocess(msg: Message) -> Bool {
        return true
    }
    
    open override func msgDesc(msg: Message) -> String {
        return ResourceUtils.loadString("im_record_msg", comment: "")
    }
    
}


