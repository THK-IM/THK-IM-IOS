//
//  IMEmojiPanelContentCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/3/1.
//  Copyright © 2024 THK. All rights reserved.
//
import UIKit

class IMEmojiPanelContentCell: UICollectionViewCell {

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setProvider(_ sender: IMMsgSender?, _ provider: IMBasePanelViewProvider) {
        self.contentView.subviews.forEach { v in
            v.removeFromSuperview()
        }
        let view = provider.contentView(sender: sender)
        self.contentView.addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}
