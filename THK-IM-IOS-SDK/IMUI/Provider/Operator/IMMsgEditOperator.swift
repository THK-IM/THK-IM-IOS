//
//  IMMsgEditOperator.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/3/2.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit

public class IMMsgEditOperator: IMMessageOperator {
    
    public func id() -> String {
        return "Edit"
    }
    
    public func title() -> String {
        return "编辑"
    }
    
    public func icon() -> UIImage? {
        return SVGImageUtils.loadSVG(named: "ic_msg_opr_edit")
    }
    
    public func onClick(sender: IMMsgSender, message: Message) {
        if message.type == MsgType.Text.rawValue {
            sender.reeditMessage(message)
        }
    }
    
    public func supportMessage(_ message: Message, _ session: Session) -> Bool {
        return message.type == MsgType.Text.rawValue && message.fromUId == IMCoreManager.shared.uId
    }
    
}
