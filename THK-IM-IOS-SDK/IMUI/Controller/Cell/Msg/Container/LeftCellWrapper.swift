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
        v.distribution = .fill
        v.spacing = 4
        
        if self.type != SessionType.Single.rawValue {
            _nickView = UILabel()
            _nickView?.snp.makeConstraints { make in
                make.height.lessThanOrEqualTo(12)
                make.width.greaterThanOrEqualTo(20)
            }
            _nickView?.textColor = UIColor.init(hex: "666666")
            _nickView?.font = UIFont.systemFont(ofSize: 12)
            v.addArrangedSubview(_nickView!)
        }
        
        v.addArrangedSubview(_containerView)
        _containerView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(48)
            make.width.greaterThanOrEqualTo(20)
        }
        
        return v
    }()
    
    override func attach(_ contentView: UIView) {
        contentView.addSubview(_avatarView)
        _avatarView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.left.equalToSuperview().offset(10)
            make.size.equalTo(42)
        }
        contentView.addSubview(_messageStack)
        _messageStack.snp.makeConstraints { make in
            make.left.equalTo(_avatarView.snp.right).offset(4)
            make.top.equalToSuperview().offset(10)
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
