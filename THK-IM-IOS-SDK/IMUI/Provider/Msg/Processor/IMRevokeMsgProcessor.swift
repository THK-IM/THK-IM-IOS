//
//  IMRevokeMsgProcessor.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/4.
//  Copyright © 2023 THK. All rights reserved.
//

import CocoaLumberjack
import Foundation
import RxSwift

public class IMRevokeMsgProcessor: IMBaseMsgProcessor {

    override public func messageType() -> Int {
        return MsgType.Revoke.rawValue
    }

    override public func send(
        _ msg: Message, _ resend: Bool = false, _ sendResult: IMSendMsgResult? = nil
    ) {
        if msg.fromUId != IMCoreManager.shared.uId {
            sendResult?(msg, CodeMessageError.Unknown)
            return
        }
        IMCoreManager.shared.api.revokeMessage(msg.fromUId, msg.sessionId, msg.msgId)
            .compose(RxTransformer.shared.io2Io())
            .subscribe(
                onError: { err in
                    sendResult?(msg, err)
                },
                onCompleted: {
                    sendResult?(msg, nil)
                }
            ).disposed(by: self.disposeBag)
    }

    override public func received(_ msg: Message) {
        self.processRevokeMsg(msg: msg)
        if msg.operateStatus & MsgOperateStatus.Ack.rawValue == 0
            && msg.fromUId != IMCoreManager.shared.uId
        {
            IMCoreManager.shared.messageModule.ackMessageToCache(msg)
        }
    }

    public override func getUserSessionName(_ sessionId: Int64, _ userId: Int64) -> String {
        if userId == IMCoreManager.shared.uId {
            return ResourceUtils.loadString("your_self")
        } else {
            return super.getUserSessionName(sessionId, userId) ?? "xxx"
        }
    }

    open func processRevokeMsg(msg: Message) {
        let senderName = self.getUserSessionName(msg.sessionId, msg.fromUId)
        let data = IMRevokeMsgData(nick: senderName)
        var existed = false
        if msg.referMsgId != nil {
            let dbMsg = try? IMCoreManager.shared.database.messageDao()
                .findByMsgId(msg.referMsgId!, msg.sessionId)
            if dbMsg != nil {
                existed = true
                try? IMCoreManager.shared.database.messageDao().delete([dbMsg!])
                SwiftEventBus.post(IMEvent.MsgDelete.rawValue, sender: dbMsg)
                if dbMsg?.fromUId == IMCoreManager.shared.uId {
                    data.content = dbMsg!.content
                    data.data = dbMsg!.data
                    data.type = dbMsg!.type
                }
            }
        }
        if existed {
            let revokeData = try? JSONEncoder().encode(data)
            msg.operateStatus =
                MsgOperateStatus.ClientRead.rawValue | MsgOperateStatus.ServerRead.rawValue
            msg.sendStatus = MsgSendStatus.Success.rawValue
            msg.data = String(data: revokeData ?? Data(), encoding: .utf8)
            try? IMCoreManager.shared.database.messageDao().insertOrIgnore([msg])
            SwiftEventBus.post(IMEvent.MsgNew.rawValue, sender: msg)
            IMCoreManager.shared.messageModule.processSessionByMessage(msg, false)
        }
    }

    override public func needReprocess(msg: Message) -> Bool {
        return true
    }

    open override func msgDesc(msg: Message) -> String {
        return ResourceUtils.loadString("im_revoke_msg")
    }

}
