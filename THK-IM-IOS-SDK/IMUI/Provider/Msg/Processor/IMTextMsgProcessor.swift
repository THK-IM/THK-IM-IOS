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
            var body = msg.content!
            if (msg.atUsers != nil && msg.atUsers!.length > 0) {
                body = AtStringUtils.replaceAtUIdsToNickname(msg.content!, msg.getAtUIds(), { id in
                    if id == -1 {
                        return User.all.nickname
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
            }
            var editFlag = ""
            if (msg.operateStatus & MsgOperateStatus.Update.rawValue > 0) {
                editFlag = "[已编辑]"
            }
            return super.sessionDesc(msg: msg) + editFlag + body
        } else {
            return super.sessionDesc(msg: msg)
        }
    }
}
