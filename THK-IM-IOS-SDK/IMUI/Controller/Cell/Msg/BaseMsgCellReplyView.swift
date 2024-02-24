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
    
    lazy private var replyView: UILabel = {
        let view = UILabel()
        view.textColor = UIColor.darkGray
        view.font = UIFont.systemFont(ofSize: 12)
        view.textAlignment = .justified
        view.numberOfLines = 2
        return view
    }()
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.addSubview(self.lineView)
        self.addSubview(self.replyView)
    }
    
    func resetHeight(_ height: CGFloat) {
        self.snp.remakeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(height)
        }
        if (height > 0) {
            self.lineView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(6)
                make.height.equalTo(16)
                make.left.equalToSuperview().offset(6)
                make.width.equalTo(4)
            }
            self.replyView.snp.remakeConstraints { [weak self] make in
                guard let sf = self else {
                    return
                }
                make.top.equalToSuperview().offset(6)
                make.height.lessThanOrEqualToSuperview()
                make.left.equalTo(sf.lineView.snp.right).offset(6)
                make.right.equalToSuperview().offset(-12)
            }
        } else {
            self.lineView.snp.remakeConstraints { make in
                make.height.equalTo(0)
            }
            self.replyView.snp.remakeConstraints { make in
                make.height.equalTo(0)
            }
        }
    }
    
    func updateContent(_ user: User, _ msg: Message) {
        let view = IMUIManager.shared.getMsgCellProvider(msg.type).replyMsgView(msg)
        if view == nil {
            let sessionDesc = IMCoreManager.shared.messageModule.getMsgProcessor(msg.type).sessionDesc(msg: msg)
            self.replyView.text = "\(user.nickname): \(sessionDesc)"
        } else {
            
        }
    }
    
}
