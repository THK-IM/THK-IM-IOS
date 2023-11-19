//
//  IMRevokeMsgCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/19.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import UIKit
import CocoaLumberjack
import RxGesture

class IMRevokeMsgCell: BaseMsgCell {
    
    private lazy var textView: UILabel = {
        let view = IMMsgLabelView()
        view.sizeToFit()
        view.numberOfLines = 0
        view.font = UIFont.systemFont(ofSize: 12)
        view.textColor = UIColor.init(hex: "aaaaaa")
        view.textAlignment = .center
        return view
    }()
    
    
    private lazy var reeditView: UILabel = {
        let view = UILabel()
        view.isUserInteractionEnabled = true
        view.sizeToFit()
        view.numberOfLines = 1
        view.font = UIFont.systemFont(ofSize: 14)
        view.textColor = UIColor.init(hex: "1988f0")
        view.text = "重新编辑"
        view.textAlignment = .center
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGesture.cancelsTouchesInView = true
        view.addGestureRecognizer(tapGesture)
        return view
    }()
    
    private lazy var revokeView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = true
        view.addSubview(textView)
        view.addSubview(reeditView)
        
        self.reeditView.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.width.equalTo(80)
            make.centerY.equalToSuperview()
            make.height.equalToSuperview()
        }
        self.textView.snp.makeConstraints { make in
            make.right.equalTo(self.reeditView.snp.left)
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalToSuperview()
        }
        return view
    }()
    
    
    override func msgView() -> UIView {
        return self.revokeView
    }
    
    override func setMessage(_ position: Int, _ messages: Array<Message>, _ session: Session, _ delegate: IMMsgCellOperator) {
        super.setMessage(position, messages, session, delegate)
        guard let msg = self.message else {
            return
        }
        if (msg.fromUId != IMCoreManager.shared.uId) {
            self.reeditView.isHidden = true
            self.reeditView.snp.updateConstraints { make in
                make.right.equalToSuperview()
                make.width.equalTo(0)
                make.centerY.equalToSuperview()
                make.height.equalToSuperview()
            }
            if (msg.data != nil) {
                do {
                    let revokeData = try JSONDecoder().decode(IMRevokeMsgData.self, from: msg.data!.data(using: .utf8) ?? Data())
                    self.textView.text = "\(revokeData.nick)撤回了一条消息"
                } catch {
                    self.textView.text = "对方撤回了一条消息"
                    DDLogError(error)
                }
            } else {
                self.textView.text = "对方撤回了一条消息"
            }
        } else {
            self.textView.text = "你撤回了一条消息"
            self.reeditView.isHidden = false
            self.reeditView.snp.updateConstraints { make in
                make.right.equalToSuperview()
                make.width.equalTo(80)
                make.centerY.equalToSuperview()
                make.height.equalToSuperview()
            }
        }
    }
    
    
    // 在子视图的 tap 手势处理函数中取消父视图的事件传递
    @objc func handleTap() {
        if (message != nil && message!.data != nil) {
            do {
                let revokeData = try JSONDecoder().decode(IMRevokeMsgData.self, from: message!.data!.data(using: .utf8) ?? Data())
                if (revokeData.type == MsgType.TEXT.rawValue && revokeData.content != nil ) {
                    self.delegate?.setEditText(text: revokeData.content!)
                }
            } catch {
                DDLogError(error)
            }
        }
    }
}
