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
        return ResourceUtils.loadString("copy")
    }

    public func icon() -> UIImage? {
        return ResourceUtils.loadImage(named: "ic_msg_opr_copy")?.withTintColor(
            IMUIManager.shared.uiResourceProvider?.inputTextColor()
                ?? UIColor.init(hex: "333333"))
    }

    public func onClick(sender: IMMsgSender, message: Message) {
        if message.type == MsgType.Text.rawValue {
            if message.atUsers != nil {
                let content = AtStringUtils.replaceAtUIdsToNickname(
                    message.content!, message.getAtUIds()
                ) { id in
                    if let member = sender.syncGetSessionMemberInfo(id) {
                        return IMUIManager.shared.nicknameForSessionMember(member.0, member.1)
                    }
                    return "\(id)"
                }
                UIPasteboard.general.string = content
                sender.showSenderMessage(
                    text: ResourceUtils.loadString("had_copyed"), success: true)
            } else {
                UIPasteboard.general.string = message.content
                sender.showSenderMessage(
                    text: ResourceUtils.loadString("had_copyed"), success: true)
            }
        }
        // TODO other msgType
    }

    public func supportMessage(_ message: Message, _ session: Session) -> Bool {
        return message.type == MsgType.Text.rawValue
    }

}
