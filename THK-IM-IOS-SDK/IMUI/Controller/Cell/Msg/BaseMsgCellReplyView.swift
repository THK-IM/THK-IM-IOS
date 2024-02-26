//
//  BaseMsgCellReplyView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/2/24.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit
import RxSwift

class BaseMsgCellReplyView: UIView {
    
    weak var sender: IMMsgSender? = nil
    private let disposeBag = DisposeBag()
    private var message: Message? = nil
    private var viewSize = CGSize(width: 0, height: 0)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    lazy private var lineView: UIImageView = {
        let view = UIImageView()
        view.image = Bubble().drawRectWithRoundedCorner(
            radius: 2, borderWidth: 0, backgroundColor: UIColor.init(hex: "#ff08AAFF"),
            borderColor: UIColor.init(hex: "#ff08AAFF"), width: 4, height: 20, pos: 0)
        return view
    }()
    
    lazy private var replyUserView: UILabel = {
        let view = UILabel()
        view.textColor = UIColor.init(hex: "#ff08AAFF")
        view.font = UIFont.systemFont(ofSize: 12)
        view.textAlignment = .justified
        view.numberOfLines = 1
        return view
    }()
    
    private var replyMsgView = UIView()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.addSubview(self.lineView)
        self.addSubview(self.replyUserView)
        self.addSubview(self.replyMsgView)
    }
    
    func resetSize(_ size: CGSize) {
        self.viewSize = size
        self.removeConstraints(self.constraints)
        self.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(size.height > 0 ? size.height + 30 : 0)
            make.width.greaterThanOrEqualTo(size.width + 30)
        }
        self.lineView.removeConstraints(self.lineView.constraints)
        self.replyUserView.removeConstraints(self.replyUserView.constraints)
        self.replyMsgView.removeConstraints(self.replyMsgView.constraints)
        if (size.height == 0) {
            self.replyMsgView.subviews.forEach { v in
                v.removeFromSuperview()
            }
            self.lineView.snp.makeConstraints { make in
                make.top.equalToSuperview()
                make.bottom.equalToSuperview()
            }
            self.replyUserView.snp.makeConstraints { make in
                make.top.equalToSuperview()
                make.bottom.equalToSuperview()
            }
            self.replyMsgView.snp.makeConstraints { make in
                make.top.equalToSuperview()
                make.bottom.equalToSuperview()
            }
        } else {
            self.lineView.snp.makeConstraints { make in
                make.top.equalToSuperview().offset(6)
                make.bottom.equalToSuperview().offset(-6)
                make.left.equalToSuperview().offset(6)
                make.width.equalTo(4)
            }
            self.replyUserView.snp.makeConstraints { [weak self] make in
                guard let sf = self else {
                    return
                }
                make.top.equalToSuperview().offset(6)
                make.height.equalTo(14)
                make.left.equalTo(sf.lineView.snp.right).offset(6)
                make.right.equalToSuperview().offset(-6)
            }
            self.replyMsgView.snp.makeConstraints { [weak self] make in
                guard let sf = self else {
                    return
                }
                make.top.equalToSuperview().offset(24)
                make.bottom.equalToSuperview().offset(-6)
                make.left.equalTo(sf.lineView.snp.right).offset(6)
                make.right.equalToSuperview().offset(-6)
            }
        }
    }
    
    func updateContent(_ user: User, _ msg: Message, _ session: Session?, _ delegate: IMMsgCellOperator?) {
        self.replyMsgView.subviews.forEach { v in
            v.removeFromSuperview()
        }
        self.replyUserView.text = "\(user.nickname):"
        
        if let view = IMUIManager.shared.getMsgCellProvider(msg.type).replyMsgView(msg, session, delegate) {
            self.replyMsgView.addSubview(view.contentView())
            view.setMessage(msg, session, delegate, true)
            
            let attributes = [NSAttributedString.Key.font: self.replyUserView.font]
            let textSize = (self.replyUserView.text! as NSString).size(withAttributes: attributes as [NSAttributedString.Key : Any])
            
            self.snp.updateConstraints { [weak self] make in
                guard let sf = self else {
                    return
                }
                make.width.greaterThanOrEqualTo(max(sf.viewSize.width, textSize.width) + 30)
            }
        }
        

    }
    
}
