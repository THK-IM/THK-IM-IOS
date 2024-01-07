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
    var session: Session? = nil
    var position: Int? = nil
    var bubbleView: UIImageView?
    
    init(_ reuseIdentifier: String, _ wrapper: CellWrapper) {
        self.cellWrapper = wrapper
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        selectionStyle = .blue
        cellWrapper.attach(contentView)
        let msgContainerView = cellWrapper.containerView()
        self.bubbleView = UIImageView()
        msgContainerView.insertSubview(self.bubbleView!, at: 0)
        let msgView = self.msgView()
        msgContainerView.addSubview(msgView)
        self.backgroundColor = UIColor.clear
        self.setupEvent()
    }
    
    func setupEvent() {
        let msgView = self.msgView()
        // 点击事件
        msgView.rx.tapGesture(configuration: { gestureRecognizer, delegate in
            delegate.touchReceptionPolicy = .custom { gestureRecognizer, touches in
                return touches.view == msgView
            }
            delegate.otherFailureRequirementPolicy = .custom { gestureRecognizer, otherGestureRecognizer in
//                if (gestureRecognizer.cancelsTouchesInView) {
//                    return true
//                }
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
        msgView.rx.longPressGesture()
            .when(.began)
            .subscribe(onNext: { [weak self]  _ in
                self?.delegate?.onMsgCellLongClick(
                    message: (self?.message)!,
                    position: self?.position ?? 0,
                    view: (self?.msgView())!
                )
            })
            .disposed(by: disposeBag)
        let resendButton = self.cellWrapper.resendButton()
        if (resendButton != nil) {
            resendButton!.rx.tap
                .subscribe(onNext: { [weak self] data in
                    guard let msg = self?.message else {
                        return
                    }
                    self?.delegate?.onMsgResendClick(message: msg)
                }).disposed(by: self.disposeBag)
        }
    }
    
    func initMsgView() {
        let msgView = self.msgView()
        bubbleView!.snp.makeConstraints { make in
            make.edges.equalTo(msgView)
        }
        msgView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        showMessageStatus()
        
        let fromUId = self.message?.fromUId
        if (self.showAvatar() && fromUId != nil) {
            self.cellWrapper.avatarView()?.isHidden = false
            IMCoreManager.shared.getUserModule()
                .queryUser(id: fromUId!)
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
        if (self.hasBubble() && fromUId != nil) {
            let position = cellPosition()
            var image: UIImage? = nil
            if (position == IMMsgPosType.Left.rawValue) {
                image = Bubble().drawRectWithRoundedCorner(
                    radius: 10, borderWidth: 0, backgroundColor: UIColor.init(hex: "ffffffff"),
                    borderColor: UIColor.init(hex: "ffffffff"), width: 40, height: 40, pos: 1)
            } else if (position == IMMsgPosType.Right.rawValue) {
                image = Bubble().drawRectWithRoundedCorner(
                    radius: 10, borderWidth: 0, backgroundColor: UIColor.init(hex: "ff35c3fd"),
                    borderColor: UIColor.init(hex: "ff35c3fd"), width: 40, height: 40, pos: 2)
            } else {
                image = Bubble().drawRectWithRoundedCorner(
                    radius: 10, borderWidth: 0, backgroundColor: UIColor.init(hex: "20000000"),
                    borderColor: UIColor.init(hex: "20000000"), width: 80, height: 30, pos: 0)
            }
            updateUserBubble(image: image)
        } else {
            updateUserBubble(image: nil)
        }
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
    
    open func setMessage(_ position: Int, _ messages: Array<Message>, _ session: Session, _ delegate: IMMsgCellOperator) {
        self.message = messages[position]
        self.position = position
        self.session = session
        initMsgView()
    }
    
    private func updateUserInfo(user: User) {
        self.cellWrapper.avatarView()?.ca_setImageUrlWithCorner(url: user.avatar ?? "", radius: 20)
        self.cellWrapper.nickView()?.text = user.nickname
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
        if (session?.type == SessionType.Single.rawValue ||
            session?.type == SessionType.Group.rawValue
        ) {
            self.readMessage()
        }
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
    open func cellPosition() -> Int {
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
