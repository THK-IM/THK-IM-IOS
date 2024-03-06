//
//  IMRevokeMsgView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/2/24.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit
import CocoaLumberjack
import RxSwift

class IMRevokeMsgView: UIView, IMsgBodyView {
    
    private weak var delegate: IMMsgCellOperator?
    private var message: Message?
    
    private lazy var textView: UILabel = {
        let view = IMMsgLabelView()
        view.sizeToFit()
        view.numberOfLines = 0
        view.font = UIFont.systemFont(ofSize: 12)
        view.textColor = UIColor.init(hex: "aaaaaa")
        view.textAlignment = .center
        view.textColor = UIColor.white
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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.isUserInteractionEnabled = true
        self.addSubview(textView)
        self.addSubview(reeditView)
        
        self.reeditView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-10)
            make.width.equalTo(80)
            make.centerY.equalToSuperview()
            make.height.equalToSuperview()
        }
        self.textView.snp.makeConstraints { [weak self] make in
            guard let sf = self else {
                return
            }
            make.right.equalTo(sf.reeditView.snp.left).offset(-10)
            make.left.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
            make.height.equalToSuperview()
        }
    }
    
    func setMessage(_ message: Message, _ session: Session?, _ delegate: IMMsgCellOperator?, _ isReply: Bool = false) {
        self.message = message
        self.delegate = delegate
        if (message.fromUId != IMCoreManager.shared.uId) {
            self.reeditView.isHidden = true
            self.reeditView.snp.updateConstraints { make in
                make.right.equalToSuperview()
                make.width.equalTo(0)
                make.centerY.equalToSuperview()
                make.height.equalToSuperview()
            }
            if (message.data != nil) {
                do {
                    let revokeData = try JSONDecoder().decode(IMRevokeMsgData.self, from: message.data!.data(using: .utf8) ?? Data())
                    self.textView.text = "\(revokeData.nick)撤回了一条消息"
                } catch {
                    self.textView.text = "对方撤回了一条消息"
                    DDLogError("\(error)")
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
                if (revokeData.type == MsgType.Text.rawValue && revokeData.content != nil ) {
                    if let sender = self.delegate?.msgSender() {
                        sender.addInputContent(text: revokeData.content!)
                        sender.openKeyboard()
                    }
                }
            } catch {
                DDLogError("\(error)")
            }
        }
    }
    
    func contentView() -> UIView {
        return self
    }
}

