//
//  IMMsgMultiSelectOperator.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/12.
//  Copyright © 2023 THK. All rights reserved.
//

import UIKit

public class IMMsgMultiSelectOperator: IMMessageOperator {
    public func id() -> String {
        return "MultiSelect"
    }
    
    public func title() -> String {
        return "多选"
    }
    
    public func icon() -> UIImage? {
        return UIImage(named: "icon_msg_operate_cancel")
    }
    
    public func onClick(sender: IMMsgSender, message: Message) {
        sender.setSelectMode(true, message: message)
    }
    
    
}
