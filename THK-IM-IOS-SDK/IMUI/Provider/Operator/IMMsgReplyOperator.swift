//
//  IMMsgReplyOperator.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/12.
//  Copyright © 2023 THK. All rights reserved.
//

import UIKit

public class IMMsgReplyOperator: IMMessageOperator {
    
    public func id() -> String {
        return "Reply"
    }
    
    public func title() -> String {
        return "回复"
    }
    
    public func icon() -> UIImage? {
        return UIImage(named: "ic_msg_opr_reply")
    }
    
    public func onClick(sender: IMMsgSender, message: Message) {
        sender.replyMessage(msg: message)
    }
    
    public func supportMessage(_ message: Message, _ session: Session) -> Bool {
        return message.type != MsgType.Revoke.rawValue
    }
    
    
}
