//
//  IMMsgRightCellWrapper.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/6.
//

import UIKit
import CocoaLumberjack

open class IMMsgRightCellWrapper: IMMsgCellWrapper {
    
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
        v.distribution = .fill
        v.spacing = 2
        
        if self.type != SessionType.Single.rawValue {
            _nickView = UILabel()
            _nickView?.textColor = UIColor.init(hex: "999999")
            _nickView?.font = UIFont.systemFont(ofSize: 12)
            v.addArrangedSubview(_nickView!)
            _nickView?.snp.makeConstraints { make in
                make.height.equalTo(14)
                make.width.greaterThanOrEqualTo(20)
            }
            v.addArrangedSubview(_containerView)
            _containerView.snp.makeConstraints { make in
                make.height.greaterThanOrEqualTo(48)
                make.width.greaterThanOrEqualTo(20)
            }
        } else {
            v.addArrangedSubview(_containerView)
            _containerView.snp.makeConstraints { make in
                make.height.greaterThanOrEqualTo(48)
                make.width.greaterThanOrEqualTo(20)
            }
        }
        
        
        return v
    }()
    
    lazy var _resendButton: UIButton = {
        let v = UIButton()
        v.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        let failedImage = ResourceUtils.loadImage(named: "ic_msg_failed")?.scaledToSize(CGSize(width: 20, height: 20))
        v.setImage(failedImage, for: .normal)
        return v
    }()
    
    lazy var _indicatorView: UIActivityIndicatorView = {
        let v = UIActivityIndicatorView()
        v.style = .medium
        v.isHidden = true
        v.tintColor = UIColor.init(hex: "999999")
        return v
    }()
    
    lazy var _readStatusView: IMReadStatusView = {
        let v = IMReadStatusView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        return v
    }()
    
    lazy var _stateStack: UIStackView = {
        let v = UIStackView(arrangedSubviews: [_readStatusView, _resendButton, _indicatorView])
        _readStatusView.snp.makeConstraints { make in
            make.size.equalTo(20)
        }
        v.axis = .horizontal
        v.alignment = .trailing
        v.distribution = .equalSpacing
        return v
    }()
    
    open override func attach(_ contentView: UIView) {
        _avatarView.contentMode = .scaleAspectFill
        contentView.addSubview(_avatarView)
        contentView.addSubview(_stateStack)
        contentView.addSubview(_messageStack)
    }
    
    open override func layoutSubViews(_ isEditing: Bool) {
        let editingWidth = isEditing ? 0 : IMUIManager.shared.msgCellAvatarWidth
        var top = 10
        if self.type != SessionType.Single.rawValue {
            top = 2
        }
        _avatarView.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(2)
            make.right.equalToSuperview().offset(-IMUIManager.shared.msgCellAvatarLeft)
            make.size.equalTo(editingWidth)
        }
        _messageStack.snp.remakeConstraints { make in
            make.right.equalTo(_avatarView.snp.left).offset(-IMUIManager.shared.msgCellAvatarRight)
            make.top.equalToSuperview().offset(top)
            make.left.greaterThanOrEqualToSuperview().offset(IMUIManager.shared.msgCellPadding)
            make.bottom.equalToSuperview().offset(-10).priority(.low)
        }
        _stateStack.snp.remakeConstraints { make in
            make.right.equalTo(_messageStack.snp.left).offset(-2)
            make.size.equalTo(20)
            make.bottom.equalTo(_containerView)
        }
    }
    
    
    open override func containerView() -> UIView {
        return self._containerView
    }
    
    open override func avatarView() -> UIImageView? {
        return self._avatarView
    }
    
    open override func nickView() -> UILabel? {
        return self._nickView
    }
    
    open override func statusView() -> UIView? {
        return self._indicatorView
    }
    
    open override func resendButton() -> UIButton? {
        return self._resendButton
    }
    
    open override func readStatusView() -> IMReadStatusView? {
        return self._readStatusView
    }
    
    open override func appear() {
        if (self._indicatorView.isHidden == false) {
            if (!self._indicatorView.isAnimating) {
                self._indicatorView.startAnimating()
            }
        }
    }
    
    open override func disAppear() {
        if (self._indicatorView.isAnimating) {
            self._indicatorView.stopAnimating()
        }
    }
    
}
