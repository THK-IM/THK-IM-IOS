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
        return UIImage(named: "ic_msg_opr_copy")
    }
    
    public func onClick(sender: IMMsgSender, message: Message) {
        if message.type == MsgType.Text.rawValue {
            UIPasteboard.general.string = message.data
            sender.showSenderMessage(text: "Copied", success: true)
        }
        // TODO other msgType
    }
    
    public func supportMessage(_ message: Message, _ session: Session) -> Bool {
        return message.type == MsgType.Text.rawValue
    }
    
    
}
