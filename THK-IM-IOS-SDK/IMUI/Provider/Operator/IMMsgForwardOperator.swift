//
//  IMMsgForwardOperator.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/12.
//  Copyright © 2023 THK. All rights reserved.
//

import UIKit

public class IMMsgForwardOperator: IMMessageOperator {
    
    public func id() -> String {
        return "Forward"
    }
    
    public func title() -> String {
        return ResourceUtils.loadString("forward", comment: "")
    }
    
    public func icon() -> UIImage? {
        return ResourceUtils.loadImage(named: "ic_msg_opr_forward")
    }
    
    public func onClick(sender: IMMsgSender, message: Message) {
        sender.forwardMessageToSession(messages: [message], forwardType: 0)
    }
    
    public func supportMessage(_ message: Message) -> Bool {
        return message.type != MsgType.Revoke.rawValue
    }
    
    
    public func supportMessage(_ message: Message, _ session: Session) -> Bool {
        if message.type == MsgType.Revoke.rawValue {
            return false
        }
        return IMUIManager.shared.uiResourceProvider?.supportFunction(functionFlag: IMChatFunction.Forward.rawValue) ?? false
    }
    
}
