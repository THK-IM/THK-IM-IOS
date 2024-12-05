//
//  IMAudioMsgCellProvider.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/5.
//

import Foundation
import UIKit

open class IMAudioMsgCellProvider: IMBaseMessageCellProvider {

    open override func messageType() -> Int {
        return MsgType.Audio.rawValue
    }

    open override func viewCellWithWrapper(_ viewType: Int, _ wrapper: IMMsgCellWrapper)
        -> IMBaseMsgCell
    {
        let identifier = self.identifier(viewType)
        return IMAudioMsgCell(identifier, messageType(), wrapper)
    }

    open override func hasBubble() -> Bool {
        return true
    }
    
    open override func msgBodyView(_ viewPosition: IMMsgPosType) -> any IMsgBodyView {
        let v = IMAudioMsgView()
        v.setViewPosition(viewPosition)
        return v
    }

}
