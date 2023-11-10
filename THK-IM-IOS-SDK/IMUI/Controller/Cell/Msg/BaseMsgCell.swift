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

open class BaseMsgCell : BaseTableCell {
    
    weak var delegate: IMMsgCellOperator? = nil
    var cellWrapper: CellWrapper
    var message: Message? = nil
    var position: Int? = nil
    
    let disposeBag: DisposeBag = DisposeBag()
    var bubbleView: UIImageView?
    
    init(_ reuseIdentifier: String, _ wrapper: CellWrapper) {
        self.cellWrapper = wrapper
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        selectionStyle = .blue
        cellWrapper.attach(contentView)
        initMsgView()
        self.backgroundColor = UIColor.clear
    }
    
    func initMsgView() {
        let msgContainerView = cellWrapper.containerView()
        self.bubbleView = UIImageView()
        msgContainerView.insertSubview(self.bubbleView!, at: 0)
        bubbleView!.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        let msgView = self.msgView()
        msgContainerView.addSubview(msgView)
        msgView.snp.makeConstraints { make in
            make.bottom.left.right.top.equalToSuperview()
        }
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
    
    func setMessage(_ position: Int, _ messages: Array<Message>, _ session: Session, _ delegate: IMMsgCellOperator) {
        self.message = messages[position]
        self.position = position
        
        showMessageStatus()
        guard let fUId = self.message?.fromUId else {
            return
        }
        if self.showAvatar() {
            self.cellWrapper.avatarView()?.isHidden = false
            IMCoreManager.shared.getUserModule()
                .getUserInfo(id: fUId)
                .compose(RxTransformer.shared.io2Main())
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
            IMCoreManager.shared.getUserModule()
                .getUserChatBubble(id: fUId)
                .compose(RxTransformer.shared.io2Main())
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
        guard let message = self.message else {
            return
        }
        switch message.sendStatus {
        case MsgSendStatus.Init.rawValue, MsgSendStatus.Sending.rawValue:
            self.cellWrapper.statusView()?.isHidden = false
            self.cellWrapper.resendButton()?.isHidden = true
            self.cellWrapper.readStatusView()?.isHidden = true
            break
        case MsgSendStatus.Failed.rawValue:
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
        self.readMessage()
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
        return msg.fromUId != 0
    }
    
    /**
     cell 位置0: 中间1: 左边2:右边
     */
    func cellPosition() -> Int {
        if cellWrapper is LeftCellWrapper {
            return IMMsgPosType.Left.rawValue
        } else if cellWrapper is RightCellWrapper {
            return IMMsgPosType.Right.rawValue
        }
        return IMMsgPosType.Mid.rawValue
    }
    
    private func readMessage() {
        if (message == nil) {
            return
        }
        if (message!.msgId <= 0 || message!.fromUId == IMCoreManager.shared.uId) {
            return
        }
        if (message!.operateStatus & MsgOperateStatus.ClientRead.rawValue) > 0
            && (message!.operateStatus & MsgOperateStatus.ServerRead.rawValue) > 0 {
            return
        }
        self.delegate?.readMessage(message!)
        message!.operateStatus = message!.operateStatus | MsgOperateStatus.ClientRead.rawValue | MsgOperateStatus.ClientRead.rawValue
    }
}
