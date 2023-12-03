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
            return
        }
        IMCoreManager.shared.api.revokeMessage(msg.fromUId, msg.sessionId, msg.msgId)
            .compose(RxTransformer.shared.io2Io())
            .subscribe(onNext: {
                sendResult?(msg, nil)
            }, onError: { err in
                sendResult?(msg, err)
            }, onCompleted: {
                
            }).disposed(by: self.disposeBag)
    }
    
    override public func received(_ msg: Message) {
        getIMRevokeMsg(msg: msg)
            .compose(RxTransformer.shared.io2Io())
            .subscribe(onNext: { newMsg in
            }, onError: { err in
                
            }, onCompleted: {
                
            }).disposed(by: self.disposeBag)
        
        if (msg.operateStatus & MsgOperateStatus.Ack.rawValue == 0 && msg.fromUId != IMCoreManager.shared.uId) {
            IMCoreManager.shared.getMessageModule().ackMessageToCache(msg)
        }
        
    }
    
    open func getNickname(msg: Message) -> Observable<String> {
        if msg.fromUId == IMCoreManager.shared.uId {
            return Observable.just("你")
        } else {
            return IMCoreManager.shared.getUserModule().getUserInfo(id: msg.fromUId)
                .flatMap { info in
                    return Observable.just(info.name)
                }
        }
    }
    
    open func getIMRevokeMsg(msg: Message) -> Observable<Message> {
        return getNickname(msg: msg).flatMap { nickname in
            let data = IMRevokeMsgData(nick: nickname)
            var existed = false
            if (msg.referMsgId != nil) {
                let dbMsg = try IMCoreManager.shared.database.messageDao()
                    .findMessageByMsgId(msg.referMsgId!, msg.sessionId)
                if (dbMsg != nil) {
                    existed = true
                    try IMCoreManager.shared.database.messageDao().deleteMessages([dbMsg!])
                    SwiftEventBus.post(IMEvent.MsgDelete.rawValue, sender: dbMsg)
                    if (dbMsg?.fromUId == IMCoreManager.shared.uId) {
                        data.content = dbMsg!.content
                        data.data = dbMsg!.data
                        data.type = dbMsg!.type
                    }
                }
            }
            let revokeData = try JSONEncoder().encode(data)
            msg.data = String(data: revokeData, encoding: .utf8)
            if (existed) {
                try IMCoreManager.shared.database.messageDao().insertOrIgnoreMessages([msg])
                SwiftEventBus.post(IMEvent.MsgNew.rawValue, sender: msg)
                IMCoreManager.shared.getMessageModule().processSessionByMessage(msg)
            }
            return Observable.just(msg)
        }
    }
    
    override public func needReprocess(msg: Message) -> Bool {
        return true
    }
    
    override public func getSessionDesc(msg: Message) -> String {
        if (msg.data != nil) {
            do {
                let revokeData = try JSONDecoder().decode(IMRevokeMsgData.self, from: msg.data!.data(using: .utf8) ?? Data())
                return "\(revokeData.nick)撤回了一条消息"
            } catch {
                DDLogError("\(error)")
            }
        }
        return ""
    }
    
}


