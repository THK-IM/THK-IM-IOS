//
//  IMMsgCopyOperator.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/12.
//  Copyright © 2023 THK. All rights reserved.
//

import UIKit

public class IMMsgCopyOperator: IMMessageOperator {
    
    public func id() -> String {
        return "Copy"
    }
    
    public func title() -> String {
        return "复制"
    }
    
    public func icon() -> UIImage? {
        return SVGImageUtils.loadSVG(named: "ic_msg_opr_copy")
    }
    
    public func onClick(sender: IMMsgSender, message: Message) {
        if message.type == MsgType.Text.rawValue {
            if message.atUsers != nil {
                let content = AtStringUtils.replaceAtUIdsToNickname(message.content!, message.getAtUIds()) { id in
                    if let member = sender.syncGetSessionMemberInfo(id) {
                        return IMUIManager.shared.nicknameForSessionMember(member.0, member.1)
                    }
                    return "\(id)"
                }
                UIPasteboard.general.string = content
                sender.showSenderMessage(text: "已复制", success: true)
            } else {
                UIPasteboard.general.string = message.content
                sender.showSenderMessage(text: "已复制", success: true)
            }
        }
        // TODO other msgType
    }
    
    public func supportMessage(_ message: Message, _ session: Session) -> Bool {
        return message.type == MsgType.Text.rawValue
    }
    
    
}
