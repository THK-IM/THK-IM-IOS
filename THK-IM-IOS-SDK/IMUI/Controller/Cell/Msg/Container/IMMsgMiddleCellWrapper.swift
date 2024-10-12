//
//  IMMsgMiddleCellWrapper.swift
//  IHK-IM-IOS
//
//  Created by vizoss on 2023/6/6.
//

import UIKit

open class IMMsgMiddleCellWrapper : IMMsgCellWrapper {
    
    lazy var _messageStack: UIStackView = {
        let v = UIStackView(arrangedSubviews: [containerView])
        v.axis = .vertical
        v.distribution = .equalSpacing
        v.alignment = .center
        return v
    }()
    
    open override func attach(_ contentView: UIView) {
        contentView.addSubview(bubbleView)
        contentView.addSubview(_messageStack)
    }
    
    open override func layoutSubViews(_ isEditing: Bool) {
        _messageStack.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.left.equalToSuperview().offset(44)
            make.right.equalToSuperview().offset(-44)
            make.bottom.equalToSuperview().offset(-10).priority(.low)
        }
        bubbleView.snp.remakeConstraints { make in
            make.edges.equalTo(self.containerView)
        }
    }
    
}
