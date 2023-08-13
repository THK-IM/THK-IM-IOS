//
//  IMMessageCellView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/28.
//

import Foundation
import UIKit
import Kingfisher
import CocoaLumberjack
import RxSwift
import RxCocoa
import RxGesture

protocol MsgCellDelegate: AnyObject {
    func onMsgCellClick(message: Message, position:Int, view: UIView)
    func onMsgCellLongClick(message: Message, position:Int, view: UIView)
    func onMsgResendClick(message: Message)
}

open class BaseMsgCell : BaseCell {
    
    weak var delegate: MsgCellDelegate? = nil
    var cellWrapper: CellWrapper
    var message: Message? = nil
    var position: Int? = nil
    var previousMessage: Message? = nil
    let disposeBag: DisposeBag = DisposeBag()
    var bubbleView: UIImageView?
    
    init(_ reuseIdentifier: String, _ wrapper: CellWrapper) {
        self.cellWrapper = wrapper
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        selectionStyle = .default
        cellWrapper.attach(contentView)
        initMsgView()
        self.backgroundColor = UIColor.clear
    }
    
    func initMsgView() {
        DDLogDebug("BaseMsgCell init")
        let msgContainerView = cellWrapper.containerView()
        self.bubbleView = UIImageView()
        msgContainerView.insertSubview(self.bubbleView!, at: 0)
        bubbleView!.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let msgView = self.msgView()
        // 点击事件
        msgContainerView.rx.tapGesture(configuration: { gestureRecognizer, delegate in
            delegate.otherFailureRequirementPolicy = .custom { gestureRecognizer, otherGestureRecognizer in
                return otherGestureRecognizer is UILongPressGestureRecognizer
            }
        })
        .when(.ended)
        .subscribe(onNext: { [weak self]  _ in
            self?.delegate?.onMsgCellClick(
                message: (self?.message)!,
                position: self?.position ?? 0,
                view: (self?.msgView())!
            )
        })
        .disposed(by: disposeBag)
        
        // 长按事件
        msgContainerView.rx.longPressGesture()
            .when(.began)
            .subscribe(onNext: { [weak self]  _ in
                self?.delegate?.onMsgCellLongClick(
                    message: (self?.message)!,
                    position: self?.position ?? 0,
                    view: (self?.msgView())!
                )
            })
            .disposed(by: disposeBag)
        
        msgContainerView.addSubview(msgView)
        msgView.snp.makeConstraints { make in
            make.bottom.left.right.top.equalToSuperview()
        }
        guard let resendButton = self.cellWrapper.resendButton() else {
            return
        }
        resendButton.rx.tap
            .subscribe(onNext: { [weak self] data in
                guard let msg = self?.message else {
                    return
                }
                self?.delegate?.onMsgResendClick(message: msg)
            }).disposed(by: self.disposeBag)
    }
    
    open func removeMsgView() {
        self.msgView().removeFromSuperview()
    }
    
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func msgView() -> UIView {
        return UIView()
    }
    
    func setMessage(_ msgs: Array<Message>, _ position: Int) {
        self.message = msgs[position]
        self.position = position
        if position >= 1 {
            self.previousMessage = msgs[position-1]
        }
        showMessageStatus()
        guard let fUId = self.message?.fUId else {
            return
        }
        if self.showAvatar() {
            self.cellWrapper.avatarView()?.isHidden = false
            IMManager.shared.getUserModule()
                .getUserInfo(id: fUId)
                .compose(DefaultRxTransformer.io2Main())
                .subscribe(onNext: { [weak self] user in
                    guard let sf = self else {
                        return
                    }
                    sf.updateUserInfo(user: user)
                }).disposed(by: disposeBag)
        } else {
            self.cellWrapper.avatarView()?.isHidden = true
        }
        if self.hasBubble() {
            IMManager.shared.getUserModule()
                .getUserChatBubble(id: fUId)
                .compose(DefaultRxTransformer.io2Main())
                .subscribe(onNext: { [weak self] image in
                    guard let sf = self else {
                        return
                    }
                    sf.updateUserBubble(image: image)
                }).disposed(by: disposeBag)
        } else {
            updateUserBubble(image: nil)
        }
    }
    
    private func updateUserInfo(user: User) {
        self.cellWrapper.avatarView()?.ca_setImageUrlWithCorner(url: user.avatar, radius: 20)
        self.cellWrapper.nickView()?.text = user.name
    }
    
    private func updateUserBubble(image: UIImage?) {
        self.bubbleView?.image = image
    }
    
    private func showMessageStatus() {
        DDLogDebug("showMessageStatus: start ")
        guard let message = self.message else {
            return
        }
        DDLogDebug("showMessageStatus: " + message.status.description)
        switch message.status {
        case MsgStatus.Init.rawValue, MsgStatus.Sending.rawValue:
            self.cellWrapper.statusView()?.isHidden = false
            self.cellWrapper.resendButton()?.isHidden = true
            self.cellWrapper.readStatusView()?.isHidden = true
            break
        case MsgStatus.SendFailed.rawValue:
            self.cellWrapper.statusView()?.isHidden = true
            self.cellWrapper.resendButton()?.isHidden = false
            self.cellWrapper.readStatusView()?.isHidden = true
            break
        default:
            self.cellWrapper.statusView()?.isHidden = true
            self.cellWrapper.resendButton()?.isHidden = true
            self.cellWrapper.readStatusView()?.isHidden = false
            break
        }
    }
    
    open override func appear() {
        self.cellWrapper.appear()
    }
    
    open override func disappear() {
        self.cellWrapper.disAppear()
        self.delegate = nil
    }
    
    open func hasBubble() -> Bool {
        return false
    }
    
    open func showAvatar() -> Bool {
        guard let msg = self.message else {
            return false
        }
        guard let previousMsg = self.previousMessage else {
            return false
        }
        return msg.fUId != previousMsg.fUId && msg.fUId != 0
    }
    
    /**
     cell 位置0: 中间1: 左边2:右边
     */
    func cellPosition() -> Int {
        if cellWrapper is LeftCellWrapper {
            return 1
        } else if cellWrapper is RightCellWrapper {
            return 2
        }
        return 0
    }
}
