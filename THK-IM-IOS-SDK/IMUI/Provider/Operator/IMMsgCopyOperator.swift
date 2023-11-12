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
        return UIImage(named: "icon_msg_operate_cancel")
    }
    
    public func onClick(sender: IMMsgSender, message: Message) {
        //
    }
    
    
}
