//
//  IMUnSupportMsgCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/6.
//

import Foundation
import UIKit

class IMUnSupportMsgCell: BaseMsgCell {
    
    private let view = IMMsgLabelView()
    
    override func msgView() -> UIView {
        self.view.sizeToFit()
        self.view.numberOfLines = 0
        self.view.font = UIFont.boldSystemFont(ofSize: 14)
        self.view.padding = UIEdgeInsets.init(top: 4, left: 4, bottom: 4, right: 4)
        if self.cellPosition() == IMMsgPosType.Left.rawValue {
            view.textColor = UIColor.black
            view.textAlignment = .left
        } else if self.cellPosition() == IMMsgPosType.Right.rawValue {
            view.textColor = UIColor.white
            view.textAlignment = .left
        } else {
            view.textColor = UIColor.white
            view.textAlignment = .center
        }
        return self.view
    }
    
    open override func setMessage(_ position: Int, _ messages: Array<Message>, _ session: Session, _ delegate: IMMsgCellOperator) {
        super.setMessage(position, messages, session, delegate)
        self.view.text = "当前版本不支持该消息类型，请更新"
    }
    
    override func hasBubble() -> Bool {
        return true
    }
}
