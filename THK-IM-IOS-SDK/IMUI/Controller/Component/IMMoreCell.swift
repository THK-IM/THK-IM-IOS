//
//  IMMoreCellView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/9.
//

import Foundation
import UIKit

class IMMoreCell: UICollectionViewCell {
    
    private let labelView = UILabel()
    private let iconView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(labelView)
        labelView.font = UIFont.systemFont(ofSize: 16)
        labelView.textAlignment = .center
        labelView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(20)
            make.bottom.equalToSuperview().offset(-20)
        }
        self.contentView.addSubview(iconView)
        
        iconView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalTo(35)
            make.height.equalTo(35)
            make.top.equalToSuperview().offset(10)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setFunction(_ function: IMBaseFunctionCellProvider) {
        self.labelView.text = function.name()
        self.iconView.image = function.icon()
    }
    
}

