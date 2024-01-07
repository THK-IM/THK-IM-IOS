//
//  LeftCellWrapper.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/6.
//

import UIKit

class LeftCellWrapper: CellWrapper {
    
    private let _avatarView = UIImageView()
    private var _nickView: UILabel? = nil
    /// 包裹消息体的容器视图
    let _containerView: UIView = {
        let v = UIView()
        v.isUserInteractionEnabled = true
        return v
    }()
    
    lazy var _messageStack: UIStackView = {
        let v = UIStackView()
        v.axis = .vertical
        v.alignment = .leading
        v.distribution = .equalSpacing
        v.spacing = 4
        
        if self.type == SessionType.Group.rawValue || self.type == SessionType.SuperGroup.rawValue {
            _nickView = UILabel()
            v.addArrangedSubview(_nickView!)
        }
        v.addArrangedSubview(_containerView)
        
        _containerView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(40)
            make.width.greaterThanOrEqualTo(20)
        }
        return v
    }()
    
    override func attach(_ contentView: UIView) {
        contentView.addSubview(_avatarView)
        _avatarView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview().offset(10)
            make.size.equalTo(42)
        }
        contentView.addSubview(_messageStack)
        var top = 10
        if self.type == SessionType.Group.rawValue || self.type == SessionType.SuperGroup.rawValue {
            top = 0
        }
        _messageStack.snp.makeConstraints { make in
            make.left.equalTo(_avatarView.snp.right).offset(4)
            make.top.equalTo(_avatarView).offset(top)
            make.width.lessThanOrEqualTo(UIScreen.main.bounds.width - 100)
            make.bottom.equalToSuperview().offset(-10).priority(.low)
        }
    }
    
    override func containerView() -> UIView {
        return self._containerView
    }
    
    override func avatarView() -> UIImageView? {
        return self._avatarView
    }
    
    override func nickView() -> UILabel? {
        return self._nickView
    }
    
    
}
