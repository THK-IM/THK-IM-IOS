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
        v.textColor = IMUIManager.shared.uiResourceProvider?.inputTextColor()
        v.font = UIFont.boldSystemFont(ofSize: 14)
        v.text = ResourceUtils.loadString("member_muted_open")
        v.numberOfLines = 1
        v.textAlignment = .center
        return v
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.muteLabel)
        self.muteLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
