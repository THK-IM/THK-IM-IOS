//
//  MiddleCellWrapper.swift
//  IM
//
//  Created by vizoss on 2023/6/6.
//

import UIKit

class MiddleCellWrapper : CellWrapper {
    
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
        _messageStack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(0)
            make.left.equalToSuperview().offset(50)
            make.right.equalToSuperview().offset(-50)
            make.bottom.equalToSuperview().offset(-10).priority(.low)
        }
    }
    
    
    override func containerView() -> UIView {
        return self._containerView
    }
    
}
