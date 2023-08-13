//
//  RightCellWrapper.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/6.
//

import UIKit
import CocoaLumberjack

class RightCellWrapper: CellWrapper {
    
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
        v.alignment = .trailing
        v.distribution = .equalSpacing
        v.spacing = 4
        
        if self.type == SessionType.Group.rawValue {
            _nickView = UILabel()
            v.addArrangedSubview(_nickView!)
            _nickView!.snp.makeConstraints { make in
                make.right.equalToSuperview().offset(0)
            }
        }
        v.addArrangedSubview(_containerView)
        
        _containerView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(40)
            make.width.greaterThanOrEqualTo(20)
        }
        return v
    }()
    
    lazy var _resendButton: UIButton = {
        let v = UIButton()
        v.frame = CGRect(x: 0, y: 0, width: 16, height: 16)
        v.setImage(UIImage(named: "chat_send_fail"), for: .normal)
        return v
    }()
    
    lazy var _indicatorView: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView()
        v.style = .medium
        v.tintColor = UIColor.init(hex: "999999")
        return v
    }()
    
    lazy var _readLabel: UIView = {
        let v = UILabel()
        return v
    }()
    
    lazy var _stateStack: UIStackView = {
        let v = UIStackView(arrangedSubviews: [_resendButton, _indicatorView, _readLabel])
        v.axis = .horizontal
        v.alignment = .trailing
        v.distribution = .equalSpacing
        return v
    }()
    
    override func attach(_ contentView: UIView) {
        contentView.addSubview(_avatarView)
        _avatarView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.right.equalToSuperview().offset(-10)
            make.size.equalTo(42)
        }
        
        contentView.addSubview(_messageStack)
        _messageStack.snp.makeConstraints { make in
            make.right.equalTo(_avatarView.snp.left).offset(-4)
            make.top.equalToSuperview().offset(0)
            make.width.lessThanOrEqualTo(UIScreen.main.bounds.width - 100)
            make.bottom.equalToSuperview().offset(-10).priority(.low)
        }
        
        contentView.addSubview(_stateStack)
        _stateStack.snp.makeConstraints { make in
            make.right.equalTo(_messageStack.snp.left).offset(-8)
            make.centerY.equalTo(_containerView)
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
    
    override func statusView() -> UIView? {
        return self._indicatorView
    }
    
    override func resendButton() -> UIButton? {
        return self._resendButton
    }
    
    override func readStatusView() -> UIView? {
        return self._readLabel
    }
    
    override func appear() {
        if (self._indicatorView.isHidden == false) {
            self._indicatorView.startAnimating()
        }
    }
    
    override func disAppear() {
        if (self._indicatorView.isHidden == false) {
            self._indicatorView.stopAnimating()
        }
    }
    
}
