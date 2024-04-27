//
//  IMSessionMemberCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/20.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

import UIKit
import RxSwift

class IMSessionMemberCell: UITableViewCell {
    
    private let disposeBag = DisposeBag()
    
    private let avatarView = UIImageView()
    private let nicknameView = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        self.setupUI()
    }
    
    private func setupUI() {
        self.contentView.addSubview(self.avatarView)
        self.contentView.addSubview(self.nicknameView)
        
        self.avatarView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(14)
            make.centerY.equalToSuperview()
            make.width.equalTo(40)
            make.height.equalTo(40)
        }
        
        self.nicknameView.snp.makeConstraints { [weak self] make in
            guard let sf = self else {
                return
            }
            make.left.equalTo(sf.avatarView.snp.right).offset(8)
            make.right.equalToSuperview().offset(-10)
            make.centerY.equalToSuperview()
            make.height.equalTo(30)
        }
        self.nicknameView.textColor = UIColor.init(hex: "333333")
        self.nicknameView.font = UIFont.boldSystemFont(ofSize: 16)
    }
    
    func setData(memberInfo: (User, SessionMember?)) {
        let nickname = IMUIManager.shared.nicknameForSessionMember(memberInfo.0, memberInfo.1)
        self.showNickname(nickname: nickname)
        if let avatar = IMUIManager.shared.avatarForSessionMember(memberInfo.0, memberInfo.1) {
            self.avatarView.renderImageByUrlWithCorner(url: avatar, radius: 20)
        } else {
            self.renderProviderAvatar(user: memberInfo.0)
        }
    }
    
    private func renderProviderAvatar(user: User) {
        let image = IMUIManager.shared.uiResourceProvider?.avatar(user: user)
        self.avatarView.image = image
        self.avatarView.layer.cornerRadius = 20
    }
    
    private func showNickname(nickname: String?) {
        if (nickname != nil) {
            self.nicknameView.text = nickname
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

