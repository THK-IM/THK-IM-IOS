//
//  IMMsgRevokeOperator.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/12.
//  Copyright © 2023 THK. All rights reserved.
//

import UIKit

public class IMMsgRevokeOperator: IMMessageOperator {

    public func id() -> String {
        return "Revoke"
    }

    public func title() -> String {
        return ResourceUtils.loadString("revoke")
    }

    public func icon() -> UIImage? {
        return ResourceUtils.loadImage(named: "ic_msg_opr_revoke")?.withTintColor(
            IMUIManager.shared.uiResourceProvider?.inputTextColor()
                ?? UIColor.init(hex: "333333"))
    }

    public func onClick(sender: IMMsgSender, message: Message) {
        weak var sender = sender
        IMCoreManager.shared.messageModule
            .getMsgProcessor(MsgType.Revoke.rawValue)
            .send(
                message, false,
                { _, err in
                    if err != nil {
                        sender?.showSenderMessage(
                            text: ResourceUtils.loadString("revoke_failed"),
                            success: false)
                    } else {
                        sender?.showSenderMessage(
                            text: ResourceUtils.loadString("revoke_success"),
                            success: false)
                    }
                })
    }

    public func supportMessage(_ message: Message, _ session: Session) -> Bool {
        if message.type == MsgType.Revoke.rawValue {
            return false
        }
        if message.fromUId != IMCoreManager.shared.uId {
            return false
        }
        // 超过120s不允许撤回
        if abs(message.cTime - IMCoreManager.shared.severTime) > 1000 * 120 {
            return false
        }
        return true
    }

}
