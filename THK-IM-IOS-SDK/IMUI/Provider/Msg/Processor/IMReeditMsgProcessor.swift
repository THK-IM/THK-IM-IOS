//
//  IMReeditMsgProcessor.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/4.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import CocoaLumberjack
import RxSwift

public class IMReeditMsgProcessor: IMBaseMsgProcessor {
    
    override public func messageType() -> Int {
        return MsgType.REEDIT.rawValue
    }
    
    override public func send(_ msg: Message, _ resend: Bool = false, _ sendResult: IMSendMsgResult? = nil) {
        guard let data = msg.data else {
            sendResult?(msg, CodeMessageError.Unknown)
            return
        }
        guard let reeditMsgData = try? JSONDecoder().decode(IMReeditMsgData.self, from: data.data(using: .utf8) ?? Data()) else {
            sendResult?(msg, CodeMessageError.Unknown)
            return
        }
        IMCoreManager.shared.api.reeditMessage(msg.fromUId, msg.sessionId, reeditMsgData.originId, reeditMsgData.edit)
            .compose(RxTransformer.shared.io2Io())
            .subscribe(onError: { err in
                sendResult?(msg, err)
            }, onCompleted: { [weak self] in
                if let success = self?.updateOriginMsg(reeditMsgData) {
                    if (success) {
                        sendResult?(msg, nil)
                    } else {
                        sendResult?(msg, CodeMessageError.Unknown)
                    }
                } else {
                    sendResult?(msg, CodeMessageError.Unknown)
                }
            }).disposed(by: self.disposeBag)
    }
    
    override public func received(_ msg: Message) {
        guard let data = msg.data else {
            return
        }
        guard let reeditMsgData = try? JSONDecoder().decode(IMReeditMsgData.self, from: data.data(using: .utf8) ?? Data()) else {
            return
        }
        let success = self.updateOriginMsg(reeditMsgData)
        if success {
            if (msg.operateStatus & MsgOperateStatus.Ack.rawValue == 0 && msg.fromUId != IMCoreManager.shared.uId) {
                IMCoreManager.shared.messageModule.ackMessageToCache(msg)
            }
        }
    }
    
    private func updateOriginMsg(_ reeditMsgData: IMReeditMsgData) -> Bool {
        guard let originMsg = try? IMCoreManager.shared.database.messageDao().findByMsgId(
            reeditMsgData.originId, reeditMsgData.sessionId
        ) else {
            return false
        }
        originMsg.content = reeditMsgData.edit + "(已编辑)"
        originMsg.data = nil
        do {
            try self.insertOrUpdateDb(originMsg)
            return true
        } catch {
            return false
        }
    }
    
    open override func needReprocess(msg: Message)-> Bool {
        return true
    }
    
}
