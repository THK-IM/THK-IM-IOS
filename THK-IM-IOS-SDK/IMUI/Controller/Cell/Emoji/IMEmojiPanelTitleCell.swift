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
        let backgroundView = UIImageView(frame: frame)
        backgroundView.image = Bubble().drawRectWithRoundedCorner(
            radius: 4, borderWidth: 0,
            backgroundColor: UIColor.init(hex: "#ffe0e0e0"), borderColor: UIColor.init(hex: "#ffe0e0e0"),
            width: 20, height: 20
        )
        self.selectedBackgroundView = backgroundView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setProvider(_ provider: IMBasePanelViewProvider) {
        self.titleView.image = provider.icon(selected: false)
    }
}
