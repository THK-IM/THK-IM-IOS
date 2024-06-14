//
//  IMRecordMsgProcessor.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/25.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import RxSwift

open class IMRecordMsgProcessor : IMBaseMsgProcessor {
    
    open override func messageType() -> Int {
        return MsgType.Record.rawValue
    }
    
    override open func received(_ msg: Message) {
        if let recordBody = try? JSONDecoder().decode(IMRecordMsgBody.self, from: msg.content?.data(using: .utf8) ?? Data()) {
            for m in recordBody.messages {
                m.operateStatus = MsgOperateStatus.Ack.rawValue | MsgOperateStatus.ClientRead.rawValue | MsgOperateStatus.ServerRead.rawValue
                m.sendStatus = MsgSendStatus.Success.rawValue
            }
            try? IMCoreManager.shared.database.messageDao().insertOrIgnore(recordBody.messages)
        }
        super.received(msg)
    }
    
    override open func reprocessingObservable(_ message: Message) -> Observable<Message>? {
        if let recordBody = try? JSONDecoder().decode(IMRecordMsgBody.self, from: message.content?.data(using: .utf8) ?? Data()) {
            try? IMCoreManager.shared.database.messageDao().insertOrIgnore(recordBody.messages)
        }
        return Observable.just(message)
    }
    
    
    override open func sendToServer(_ message: Message) -> Observable<Message> {
        if (message.content == nil) {
            return super.sendToServer(message)
        }
        guard let recordBody = try? JSONDecoder().decode(IMRecordMsgBody.self, from: message.content!.data(using: .utf8) ?? Data()) else {
            return super.sendToServer(message)
        }

        var recordSessionId: Int64? = nil
        var recordFromUIds = Set<Int64>()
        var recordClientIds = Set<Int64>()
        for subMessage in recordBody.messages {
            recordSessionId = subMessage.sessionId
            recordFromUIds.insert(subMessage.fromUId)
            recordClientIds.insert(subMessage.id)
        }
        if (recordSessionId == nil || recordFromUIds.count == 0 || recordClientIds.count == 0) {
            return super.sendToServer(message)
        }

        return IMCoreManager.shared.api.forwardMessages(
            message,
            forwardSid: recordSessionId!,
            fromUserIds: recordFromUIds,
            clientMsgIds: recordClientIds
        )
    }
    
    override public func needReprocess(msg: Message) -> Bool {
        return true
    }
    
    override open func msgDesc(msg: Message) -> String {
        return "[会话记录]"
    }
}
