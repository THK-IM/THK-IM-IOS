//
//  IMTextMsgCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/6.
//

import UIKit
import CocoaLumberjack

class IMTextMsgCell: BaseMsgCell {
    
    private let textView = IMMsgLabelView()
    
    override func msgView() -> UIView {
        self.textView.sizeToFit()
        self.textView.numberOfLines = 0
        self.textView.font = UIFont.boldSystemFont(ofSize: 16)
        self.textView.padding = UIEdgeInsets.init(top: 8, left: 8, bottom: 8, right: 8)
        
        if self.cellPosition() == IMMsgPosType.Left.rawValue {
            self.textView.textColor = UIColor.black
            self.textView.textAlignment = .left
        } else if self.cellPosition() == IMMsgPosType.Right.rawValue {
            self.textView.textColor = UIColor.black
            self.textView.textAlignment = .left
        } else {
            self.textView.textColor = UIColor.white
            self.textView.textAlignment = .center
        }
        return self.textView
    }
    
    override func hasBubble() -> Bool {
        return true
    }
    
    override func setMessage(_ position: Int, _ messages: Array<Message>, _ session: Session, _ delegate: IMMsgCellOperator) {
        super.setMessage(position, messages, session, delegate)
        self.textView.text = self.message!.content
    }
    
    
}
