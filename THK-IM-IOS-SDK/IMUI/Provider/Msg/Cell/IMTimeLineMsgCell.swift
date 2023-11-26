//
//  IMTimeLineMsgCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/7.
//

import UIKit

class IMTimeLineMsgCell: BaseMsgCell {
    private let view = IMMsgLabelView()
    override func msgView() -> UIView {
        self.view.sizeToFit()
        self.view.numberOfLines = 0
        self.view.font = UIFont.systemFont(ofSize: 12)
        self.view.textColor = UIColor.white
        self.view.textAlignment = .center
        self.view.padding = UIEdgeInsets(top: 2, left: 6, bottom: 2, right: 6)
        return self.view
    }
    
    override func hasBubble() -> Bool {
        return true
    }
    
    open override func setMessage(_ mode: Int, _ position: Int, _ messages: Array<Message>, _ session: Session, _ delegate: IMMsgCellOperator) {
        super.setMessage(mode, position, messages, session, delegate)
        guard let msg = self.message else {
            return
        }
        let dateString = DateUtils.timeToMsgTime(ms: msg.cTime, now: IMCoreManager.shared.severTime)
        self.view.text = dateString
    }
    
}
