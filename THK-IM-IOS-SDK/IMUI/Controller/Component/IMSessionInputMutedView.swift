//
//  IMSessionInputMutedView.swift
//  THK-IM-IOS
//
//  Created by macmini on 2025/1/6.
//  Copyright © 2025 THK. All rights reserved.
//

import UIKit

class IMSessionInputMutedView: UIView {

    private lazy var muteLabel: UILabel = {
        let v = UILabel()
        v.textColor = .white
        v.font = UIFont.systemFont(ofSize: 16)
        v.text = ResourceUtils.loadString("member_muted_open")
        v.numberOfLines = 1
        v.textAlignment = .center
        return v
    }()

    private lazy var bgView: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 20
        v.layer.backgroundColor = UIColor.init(hex: "7F7F7F").cgColor
        v.addSubview(self.muteLabel)
        self.muteLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
        }
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(self.bgView)
        self.bgView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(14)
            make.right.equalToSuperview().offset(-14)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
