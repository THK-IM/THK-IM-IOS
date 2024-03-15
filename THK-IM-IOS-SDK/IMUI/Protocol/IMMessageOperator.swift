//
//  IMMessageOperator.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/12.
//  Copyright © 2023 THK. All rights reserved.
//

import UIKit

public protocol IMMessageOperator: AnyObject {
    func id()-> String
    func title() -> String
    func icon() -> UIImage?
    func onClick(sender: IMMsgSender, message: Message)
    func supportMessage(_ message: Message, _ session: Session) -> Bool
}
