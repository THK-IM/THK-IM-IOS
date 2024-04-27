//
//  IMMessageOperatorItemView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/12.
//  Copyright © 2023 THK. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

public typealias OnItemClick = () -> Void

public class IMMessageOperatorItemView: UIView {
    private weak var msgOperator: IMMessageOperator?
    private weak var sender: IMMsgSender?
    private var message: Message?
    private var onItemClick: OnItemClick?
    private lazy var titleView: UILabel = {
        let v = UILabel()
        v.font = UIFont.systemFont(ofSize: 12)
        v.textColor = .black
        v.textAlignment = .center
        return v
    }()
    
    private lazy var iconView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFit
        return v
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.iconView)
        self.iconView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(0)
            make.centerX.equalToSuperview()
            make.size.equalTo(34)
        }
        self.addSubview(self.titleView)
        self.titleView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-8)
            make.centerX.equalToSuperview()
            make.height.equalTo(16)
        }
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        self.addGestureRecognizer(tapGestureRecognizer)
        self.isUserInteractionEnabled = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func viewTapped() {
        guard let msgOperator = self.msgOperator else {
            return
        }
        guard let sender = self.sender else {
            return
        }
        guard let message = self.message else {
            return
        }
        msgOperator.onClick(sender: sender, message: message)
        self.onItemClick?()
    }
    
    func setIMMessageOperator(_ msgOperator: IMMessageOperator, _ sender: IMMsgSender, _ message: Message, _ onItemClick: OnItemClick? ) {
        self.msgOperator = msgOperator
        self.onItemClick = onItemClick
        self.sender = sender
        self.message = message
        self.iconView.image = msgOperator.icon()
        self.titleView.text = msgOperator.title()
    }
}
