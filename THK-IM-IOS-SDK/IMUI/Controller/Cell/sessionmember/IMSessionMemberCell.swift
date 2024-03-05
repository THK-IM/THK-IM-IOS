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
            make.left.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
            make.width.equalTo(42)
            make.height.equalTo(42)
        }
        
        self.nicknameView.snp.makeConstraints { [weak self] make in
            guard let sf = self else {
                return
            }
            make.left.equalTo(sf.avatarView.snp.right).offset(10)
            make.right.equalToSuperview().offset(-10)
            make.centerY.equalToSuperview()
            make.height.equalTo(30)
        }
        self.nicknameView.textColor = UIColor.init(hex: "333333")
        self.nicknameView.font = UIFont.systemFont(ofSize: 16)
    }
    
    func setData(memberInfo: (User, SessionMember?)) {
        self.avatarView.renderImageByUrlWithCorner(url: memberInfo.0.avatar ?? "", radius: 10)
        if (memberInfo.1 != nil && memberInfo.1!.noteName != nil && !memberInfo.1!.noteName!.isEmpty ) {
            self.showNickname(nickname: memberInfo.1!.noteName!)
        } else {
            self.showNickname(nickname: memberInfo.0.nickname)
        }
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

