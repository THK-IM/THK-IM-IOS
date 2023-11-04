//
//  IMMsgCellOperator.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/10/2.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import UIKit

protocol IMMsgCellOperator: AnyObject {
    func onMsgCellClick(message: Message, position:Int, view: UIView)
    func onMsgCellLongClick(message: Message, position:Int, view: UIView)
    func onMsgResendClick(message: Message)
    func isSelectMode() ->Bool
    func isItemSelected(message: Message) ->Bool
    func onSelected(message: Message, selected: Bool)
    func readMessage(_ message: Message)
}
