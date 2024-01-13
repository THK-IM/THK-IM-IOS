//
//  GroupTableCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/13.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit
import RxSwift

class GroupTableCell: UITableViewCell {
    
    private let disposeBag = DisposeBag()
    
    private let avatarView = UIImageView()
    private let nicknameView = UILabel()
    private let relationView = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        
        self.nicknameView.snp.makeConstraints { make in
            make.left.equalTo(self.avatarView.snp.right).offset(10)
            make.right.equalToSuperview().offset(-10)
            make.centerY.equalToSuperview()
            make.height.equalTo(30)
        }
        self.nicknameView.textColor = UIColor.init(hex: "333333")
        self.nicknameView.font = UIFont.systemFont(ofSize: 16)
    }
    
    func setData(group: Group) {
        showNickname(nickname: group.name)
        self.avatarView.ca_setImageUrlWithCorner(url: group.avatar, radius: 8)
    }
    
    private func showNickname(nickname: String?) {
        if (nickname != nil) {
            self.nicknameView.text = nickname
        }
    }
    
    
}
