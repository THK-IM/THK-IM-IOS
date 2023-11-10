//
//  IMTabCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/9.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import UIKit

class IMTabCell: UICollectionViewCell {
    
    private let icon = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(icon)
        
        icon.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalTo(35)
            make.height.equalTo(35)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func setProvider(_ provider: IMBasePanelViewProvider) {
        self.icon.image = provider.icon(selected: false)
    }
}
