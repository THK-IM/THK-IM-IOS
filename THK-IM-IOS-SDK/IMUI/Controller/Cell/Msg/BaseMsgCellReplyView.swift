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
            radius: 2, borderWidth: 0, backgroundColor: UIColor.init(hex: "#ff999999"),
            borderColor: UIColor.init(hex: "#ff999999"), width: 4, height: 20, pos: 0)
        return view
    }()
    
    lazy private var replyUserView: UILabel = {
        let view = UILabel()
        view.textColor = UIColor.darkGray
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
        self.snp.remakeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(size.height)
            make.width.greaterThanOrEqualTo(size.width)
        }
        if (size.height > 0) {
            self.lineView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(6)
                make.height.equalTo(16)
                make.left.equalToSuperview().offset(6)
                make.width.equalTo(4)
            }
            self.replyUserView.snp.remakeConstraints { [weak self] make in
                guard let sf = self else {
                    return
                }
                make.top.equalToSuperview().offset(6)
                make.height.lessThanOrEqualToSuperview()
                make.left.equalTo(sf.lineView.snp.right).offset(6)
            }
            self.replyMsgView.snp.remakeConstraints { [weak self] make in
                guard let sf = self else {
                    return
                }
                make.top.equalToSuperview().offset(6)
                make.height.lessThanOrEqualToSuperview()
                make.left.equalTo(sf.replyUserView.snp.right)
                make.right.equalToSuperview().offset(-6)
            }
        } else {
            self.replyMsgView.subviews.forEach { v in
                v.removeFromSuperview()
            }
            self.lineView.snp.remakeConstraints { make in
                make.height.equalTo(0)
            }
            self.replyUserView.snp.remakeConstraints { make in
                make.height.equalTo(0)
            }
            self.replyMsgView.snp.remakeConstraints { make in
                make.height.equalTo(0)
            }
        }
    }
    
    func updateContent(_ user: User, _ msg: Message, _ session: Session?, _ delegate: IMMsgCellOperator?) {
        self.replyMsgView.subviews.forEach { v in
            v.removeFromSuperview()
        }
        self.replyUserView.text = "\(user.nickname):"
        
        let view = IMUIManager.shared.getMsgCellProvider(msg.type).replyMsgView(msg, session, delegate)
        self.replyMsgView.addSubview(view!)
        view?.setMessage(msg, session, delegate, true)
        
        let attributes = [NSAttributedString.Key.font: self.replyUserView.font]
        let textSize = (self.replyUserView.text! as NSString).size(withAttributes: attributes as [NSAttributedString.Key : Any])
        self.replyUserView.snp.remakeConstraints { [weak self] make in
            guard let sf = self else {
                return
            }
            make.top.equalToSuperview().offset(6)
            make.width.equalTo(textSize.width+6)
            make.height.lessThanOrEqualToSuperview()
            make.left.equalTo(sf.lineView.snp.right).offset(6)
        }
        
        self.snp.remakeConstraints { [weak self] make in
            guard let sf = self else {
                return
            }
            make.top.equalToSuperview()
            make.left.equalToSuperview().priority(.required)
            make.right.equalToSuperview().priority(.required)
            make.height.equalTo(sf.viewSize.height)
            make.width.greaterThanOrEqualTo(sf.viewSize.width + textSize.width + 30)
        }
        
    }
    
}
