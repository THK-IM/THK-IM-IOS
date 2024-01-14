//
//  SessionMemberCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/13.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit
import RxSwift

class SessionMemberCell: UICollectionViewCell {
    
    private let avatarView = UIImageView()
    private let nicknameView = UILabel()
    private let disposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.contentView.addSubview(avatarView)
        self.avatarView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.centerX.equalToSuperview()
            make.height.equalTo(48)
            make.width.equalTo(48)
        }
        self.contentView.addSubview(nicknameView)
        self.nicknameView.snp.makeConstraints { make in
            make.top.equalTo(self.avatarView.snp.bottom).offset(6)
            make.centerX.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(20)
        }
        self.nicknameView.textAlignment = .center
        self.nicknameView.textColor = UIColor.init(hex: "333333")
        self.nicknameView.font = UIFont.systemFont(ofSize: 14)
    }
    
    func setMemberId(id: Int64) {
        IMCoreManager.shared.userModule.queryUser(id: id)
            .compose(RxTransformer.shared.io2Main())
            .subscribe(onNext: { [weak self] user in
                self?.avatarView.ca_setImageUrlWithCorner(url: user.avatar ?? "", radius: 10)
                self?.nicknameView.text = user.nickname
            }).disposed(by: self.disposeBag)
    }
}
