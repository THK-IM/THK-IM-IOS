//
//  ContactTableCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/7.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit
import RxSwift

class ContactTableCell: UITableViewCell {
    
    private let disposeBag = DisposeBag()
    
    private let avatarView = UIImageView()
    private let nicknameView = UILabel()
    private let relationView = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupUI()
    }
    
    private func setupUI() {
        self.contentView.addSubview(self.avatarView)
        self.contentView.addSubview(self.nicknameView)
        self.contentView.addSubview(self.relationView)
        
        self.avatarView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
            make.width.equalTo(42)
            make.height.equalTo(42)
        }
        self.relationView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-10)
            make.centerY.equalToSuperview()
            make.width.greaterThanOrEqualTo(100)
            make.height.equalTo(30)
        }
        self.relationView.textColor = UIColor.init(hex: "666666")
        self.relationView.font = UIFont.systemFont(ofSize: 10)
        
        self.nicknameView.snp.makeConstraints { make in
            make.left.equalTo(self.avatarView.snp.right).offset(10)
            make.right.equalTo(self.relationView.snp.left).offset(-10)
            make.centerY.equalToSuperview()
            make.height.equalTo(30)
        }
        self.nicknameView.textColor = UIColor.init(hex: "333333")
        self.nicknameView.font = UIFont.systemFont(ofSize: 16)
    }
    
    func setData(contact: Contact) {
        let uId = contact.id
        IMCoreManager.shared.userModule.queryUser(id: uId)
            .subscribe(onNext: { [weak self] user in
                self?.showAvatar(user: user, contact: contact)
            }).disposed(by: self.disposeBag)
        showNickname(nickname: contact.noteName)
        showRelation(relation: contact.relation)
    }
    
    private func showAvatar(user: User, contact: Contact) {
        self.avatarView.ca_setImageUrlWithCorner(url: user.avatar ?? "", radius: 8)
        if (contact.noteName == nil) {
            self.showNickname(nickname: user.nickname)
        }
    }
    
    private func showNickname(nickname: String?) {
        if (nickname != nil) {
            self.nicknameView.text = nickname
        }
    }
    
    private func showRelation(relation: Int) {
        var str = ""
        if (relation & 8 > 0) {
            str += "我关注了他;"
        }
        if (relation & 16 > 0) {
            str += "他关注了我;"
        }
        if (relation & 32 > 0) {
            str += "好友关系;"
        }
        self.relationView.text = str
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
