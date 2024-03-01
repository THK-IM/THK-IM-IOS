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
            make.centerX.equalToSuperview()
            make.width.equalTo(30)
            make.height.equalTo(30)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setProvider(_ provider: IMBasePanelViewProvider) {
        self.titleView.image = provider.icon(selected: false)
    }
}
