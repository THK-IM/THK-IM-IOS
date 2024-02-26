//
//  IMTimeLineMsgView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/2/24.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit
import CocoaLumberjack
import RxSwift

class IMTimeLineMsgView: IMMsgLabelView, IMsgView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.sizeToFit()
        self.numberOfLines = 0
        self.font = UIFont.systemFont(ofSize: 12)
        self.textColor = UIColor.white
        self.textAlignment = .center
        self.padding = UIEdgeInsets(top: 2, left: 20, bottom: 2, right: 20)
    }
    
    
    func setMessage(_ message: Message, _ session: Session?, _ delegate: IMMsgCellOperator?, _ isReply: Bool = false) {
        let dateString = DateUtils.timeToMsgTime(ms: message.cTime, now: IMCoreManager.shared.severTime)
        self.text = dateString
    }
    
    func contentView() -> UIView {
        return self
    }
}
