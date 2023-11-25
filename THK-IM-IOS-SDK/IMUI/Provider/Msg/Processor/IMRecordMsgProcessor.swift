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
    
    
    override open func getSessionDesc(msg: Message) -> String {
        return "[会话记录]"
    }
}
