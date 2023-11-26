//
//  IMTextMsgCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/6.
//

import UIKit
import CocoaLumberjack

class IMTextMsgCell: BaseMsgCell {
    
    private lazy var textView: IMMsgLabelView = {
        let view = IMMsgLabelView()
        view.sizeToFit()
        view.numberOfLines = 0
        view.font = UIFont.boldSystemFont(ofSize: 16)
        view.padding = UIEdgeInsets.init(top: 8, left: 8, bottom: 8, right: 8)
        
        if self.cellPosition() == IMMsgPosType.Left.rawValue {
            view.textColor = UIColor.black
            view.textAlignment = .left
        } else if self.cellPosition() == IMMsgPosType.Right.rawValue {
            view.textColor = UIColor.black
            view.textAlignment = .left
        } else {
            view.textColor = UIColor.white
            view.textAlignment = .center
        }
        return view
    }()
    
    
    
    override func msgView() -> UIView {
        return self.textView
    }
    
    override func hasBubble() -> Bool {
        return true
    }
    
    open override func setMessage(_ mode: Int, _ position: Int, _ messages: Array<Message>, _ session: Session, _ delegate: IMMsgCellOperator) {
        super.setMessage(mode, position, messages, session, delegate)
        self.textView.text = self.message!.content
    }
    
    
}
