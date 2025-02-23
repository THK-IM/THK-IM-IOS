//
//  IMUnsupportMsgView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/2/24.
//  Copyright © 2024 THK. All rights reserved.
//

import CocoaLumberjack
import RxSwift
import UIKit

class IMUnSupportMsgView: IMMsgLabelView, IMsgBodyView {

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
        self.textColor = UIColor.init(hex: "0A0E10")
        self.font = UIFont.systemFont(ofSize: 14)
        self.padding = UIEdgeInsets.init(top: 4, left: 4, bottom: 4, right: 4)
    }
    
    func setViewPosition(_ position: IMMsgPosType) {
        
    }

    func setMessage(
        _ message: Message, _ session: Session?, _ delegate: IMMsgCellOperator?
    ) {
        self.text = ResourceUtils.loadString("not_support_msg_update_client")
    }

    func contentView() -> UIView {
        return self
    }
}
