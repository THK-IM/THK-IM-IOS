//
//  IMUnicodeEmojiCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/8.
//

import Foundation
import UIKit

class IMUnicodeEmojiCell: UICollectionViewCell {
    
    private let labelView = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(labelView)
        labelView.font = UIFont.systemFont(ofSize: 32)
        labelView.textAlignment = .center
        labelView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setEmoji(_ unicode: String) {
        self.labelView.text = unicode
    }
    
}
