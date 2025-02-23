//
//  IMFunctionCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/9.
//

import Foundation
import UIKit

class IMFunctionCell: UICollectionViewCell {

    private let labelView = UILabel()
    private let iconView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(labelView)
        labelView.font = UIFont.systemFont(ofSize: 12)
        labelView.textColor = UIColor.init(hex: "333333")
        labelView.textAlignment = .center
        labelView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.height.equalTo(20)
            make.bottom.equalToSuperview().offset(-14)
        }
        self.contentView.addSubview(iconView)

        iconView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(14)
            make.size.equalTo(36)
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
