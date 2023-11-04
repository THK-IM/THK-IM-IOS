//
//  ReeditMsgProcessor.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/4.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation

public class ReeditMsgProcessor: BaseMsgProcessor {
    
    
    override public func messageType() -> Int {
        return MsgType.REEDIT.rawValue
    }
    
}
