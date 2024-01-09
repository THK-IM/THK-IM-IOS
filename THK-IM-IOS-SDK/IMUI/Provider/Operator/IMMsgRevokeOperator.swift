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
        return "撤回"
    }
    
    public func icon() -> UIImage? {
        return UIImage(named: "icon_msg_operate_cancel")
    }
    
    public func onClick(sender: IMMsgSender, message: Message) {
        IMCoreManager.shared.messageModule
            .getMsgProcessor(MsgType.Revoke.rawValue)
            .send(message, false, { _,_ in 
                
            })
    }
    
    
}
