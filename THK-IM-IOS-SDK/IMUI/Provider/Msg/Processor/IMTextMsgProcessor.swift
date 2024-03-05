//
//  IMTextMsgProcessor.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/21.
//

import Foundation

open class IMTextMsgProcessor : IMBaseMsgProcessor {
    
    open override func messageType() -> Int {
        return MsgType.Text.rawValue
    }
    
    open override func sessionDesc(msg: Message) -> String {
        if (msg.content != nil) {
            if (msg.atUsers != nil && msg.atUsers!.length > 0) {
                let content = AtStringUtils.replaceAtUIdsToNickname(msg.content!, msg.atUsers!, { id in
                    if id == -1 {
                        return "All"
                    }
                    if let sessionMember = IMCoreManager.shared.database.sessionMemberDao().findSessionMember(msg.sessionId, id) {
                        if let noteName = sessionMember.noteName {
                            if (!noteName.isEmpty) {
                                return noteName
                            }
                        }
                    }
                    if let user = IMCoreManager.shared.database.userDao().findById(id) {
                        return user.nickname
                    }
                    return ""
                })
                return super.sessionDesc(msg: msg) + content
            }
            return super.sessionDesc(msg: msg) + String(msg.content!)
        } else {
            return super.sessionDesc(msg: msg)
        }
    }
}
