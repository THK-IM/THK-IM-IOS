//
//  IMMsgMiddleCellWrapper.swift
//  IHK-IM-IOS
//
//  Created by vizoss on 2023/6/6.
//

import UIKit

class IMMsgMiddleCellWrapper : IMMsgCellWrapper {
    
    /// 包裹消息体的容器视图
    let _containerView: UIView = {
        let v = UIView()
        v.isUserInteractionEnabled = true
        return v
    }()
    
    lazy var _messageStack: UIStackView = {
        let v = UIStackView(arrangedSubviews: [_containerView])
        v.axis = .vertical
        v.distribution = .equalSpacing
        v.alignment = .center
        return v
    }()
    
    override func attach(_ contentView: UIView) {
        contentView.addSubview(_messageStack)
    }
    
    override func layoutSubViews(_ isEditing: Bool) {
        _messageStack.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.left.equalToSuperview().offset(44)
            make.right.equalToSuperview().offset(-44)
            make.bottom.equalToSuperview().offset(-10).priority(.low)
        }
    }
    
    
    override func containerView() -> UIView {
        return self._containerView
    }
    
}
