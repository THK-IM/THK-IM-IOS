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
        return ResourceUtils.loadString("multi_select", comment: "")
    }

    public func icon() -> UIImage? {
        return ResourceUtils.loadImage(named: "ic_msg_opr_multi_select")
    }

    public func onClick(sender: IMMsgSender, message: Message) {
        sender.setSelectMode(true, message: message)
    }

    public func supportMessage(_ message: Message, _ session: Session) -> Bool {
        return true
    }

}
