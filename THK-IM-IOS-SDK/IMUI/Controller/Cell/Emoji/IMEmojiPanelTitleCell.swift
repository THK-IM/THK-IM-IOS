//
//  IMEmojiPanelTitleCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/9.
//  Copyright © 2023 THK. All rights reserved.
//

import UIKit

class IMEmojiPanelTitleCell: UICollectionViewCell {

    private let titleView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(titleView)
        titleView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(30)
            make.height.equalTo(30)
        }
        let backgroundView = UIView(frame: frame)
        backgroundView.layer.cornerRadius = 6
        backgroundView.layer.backgroundColor =
        IMUIManager.shared.uiResourceProvider?.inputBgColor()?.cgColor
        self.selectedBackgroundView = backgroundView
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setProvider(_ provider: IMBasePanelViewProvider) {
        self.titleView.image = provider.icon(selected: false)
    }
}
