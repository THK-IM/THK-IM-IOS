//
//  IMBaseMsgCell.swift
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

open class IMBaseMsgCell : IMBaseTableCell {
    
    open weak var delegate: IMMsgCellOperator? = nil
    open var cellWrapper: IMMsgCellWrapper
    open var message: Message? = nil
    open var session: Session? = nil
    open var position: Int? = nil
    open var bubbleView = UIImageView()
    open var replyView = IMMsgReplyView()
    
    public init(_ reuseIdentifier: String, _ wrapper: IMMsgCellWrapper) {
        self.cellWrapper = wrapper
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        selectionStyle = .blue
        cellWrapper.attach(contentView)
        cellWrapper.layoutSubViews(self.isEditing)
        let msgContainerView = cellWrapper.containerView()
        msgContainerView.insertSubview(self.bubbleView, at: 0)
        msgContainerView.addSubview(self.replyView)
        let msgView = self.msgView().contentView()
        msgContainerView.addSubview(msgView)
        self.backgroundColor = UIColor.clear
        self.setupEvent()
    }
    
    func setupEvent() {
        self.replyView.rx.tapGesture(configuration: { gestureRecognizer, delegate in
            delegate.otherFailureRequirementPolicy = .custom { gestureRecognizer, otherGestureRecognizer in
                return otherGestureRecognizer is UILongPressGestureRecognizer
            }
        })
        .when(.ended)
        .subscribe(onNext: { [weak self]  _ in
            guard let sf = self else {
                return
            }
            guard let referMsg = sf.message?.referMsg else {
                return
            }
            sf.delegate?.onMsgReferContentClick(message: referMsg, view: sf.replyView)
        })
        .disposed(by: disposeBag)
        
        let msgView = self.msgView().contentView()
        // 点击事件
        msgView.rx.tapGesture(configuration: { gestureRecognizer, delegate in
            delegate.otherFailureRequirementPolicy = .custom { gestureRecognizer, otherGestureRecognizer in
                return otherGestureRecognizer is UILongPressGestureRecognizer
            }
        })
        .when(.ended)
        .subscribe(onNext: { [weak self]  _ in
            self?.delegate?.onMsgCellClick(
                message: (self?.message)!,
                position: self?.position ?? 0,
                view: (self?.msgView().contentView())!
            )
        })
        .disposed(by: disposeBag)
        
        // 长按事件
        cellWrapper.containerView().rx.longPressGesture()
            .when(.began)
            .subscribe(onNext: { [weak self]  _ in
                guard let sf = self else {
                    return
                }
                if !sf.canSelected() {
                    return
                }
                sf.delegate?.onMsgCellLongClick(
                    message: (sf.message)!,
                    position: sf.position ?? 0,
                    view: sf.msgView().contentView()
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
        let avatarView = self.cellWrapper.avatarView()
        avatarView?.rx.tapGesture(configuration: { [weak self] gestureRecognizer, delegate in
            delegate.touchReceptionPolicy = .custom { gestureRecognizer, touches in
                return touches.view == self?.cellWrapper.avatarView()
            }
            delegate.otherFailureRequirementPolicy = .custom { gestureRecognizer, otherGestureRecognizer in
                return otherGestureRecognizer is UILongPressGestureRecognizer
            }
        })
        .when(.ended)
        .subscribe(onNext: { [weak self]  _ in
            self?.delegate?.onMsgSenderClick(
                message: (self?.message)!,
                position: self?.position ?? 0,
                view: (self?.cellWrapper.avatarView())!
            )
        }).disposed(by: disposeBag)
        
        avatarView?.rx.longPressGesture()
            .when(.began)
            .subscribe(onNext: { [weak self]  _ in
                self?.delegate?.onMsgSenderLongClick(
                    message: (self?.message)!,
                    position: self?.position ?? 0,
                    view: (self?.msgView().contentView())!
                )
            })
            .disposed(by: disposeBag)
        if let readStatusView = self.cellWrapper.readStatusView() {
            readStatusView.rx.tapGesture(configuration: { [weak self] gestureRecognizer, delegate in
                delegate.touchReceptionPolicy = .custom { gestureRecognizer, touches in
                    return touches.view == self?.cellWrapper.readStatusView()
                }
                delegate.otherFailureRequirementPolicy = .custom { gestureRecognizer, otherGestureRecognizer in
                    return otherGestureRecognizer is UILongPressGestureRecognizer
                }
            })
            .when(.ended)
            .subscribe(onNext: { [weak self]  _ in
                self?.delegate?.onMsgReadStatusClick(message: (self?.message)!)
            }).disposed(by: self.disposeBag)
        }
    }
    
    open func setMessage(_ position: Int, _ messages: Array<Message>, _ session: Session, _ delegate: IMMsgCellOperator) {
        self.message = messages[position]
        self.position = position
        self.session = session
        layoutMessageView()
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        self.cellWrapper.layoutSubViews(self.isEditing)
    }
    
    
    func layoutMessageView() {
        self.initUser()
        self.initBubble()
        self.initMsgContent()
        self.initMessageStatus()
    }
    
    private func initReplyMsg() {
        guard let msg = self.message?.referMsg else {
            return
        }
        IMCoreManager.shared.userModule.queryUser(id: msg.fromUId)
        .compose(RxTransformer.shared.io2Main())
        .subscribe(onNext: { [weak self] user in
            self?.showReplyMsg(user)
        }).disposed(by: self.disposeBag)
    }
    
    private func showReplyMsg(_ user: User) {
        guard let msg = self.message?.referMsg else {
            return
        }
        self.replyView.updateContent(user, msg, self.session, self.delegate)
    }
    
    open func initMsgContent() {
        self.bubbleView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        var size = CGSize(width: 0, height: 0)
        if let msg = message?.referMsg {
            size = IMUIManager.shared.getMsgCellProvider(msg.type).replyMsgViewSize(msg, self.session)
            self.replyView.resetSize(size)
            self.initReplyMsg()
        } else {
            self.replyView.resetSize(size)
        }
        let msgView = self.msgView().contentView()
        msgView.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(size.height > 0 ? size.height + 30 : 0) // 补齐回复人高度
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalToSuperview()
        }
    }
    
    open func initUser() {
        let fromUId = self.message?.fromUId
        if (self.showAvatar() && fromUId != nil && self.cellWrapper.avatarView() != nil) {
            guard let delegate = self.delegate else {
                return
            }
            guard let sender = delegate.msgSender() else {
                IMCoreManager.shared.userModule
                    .queryUser(id: fromUId!)
                    .compose(RxTransformer.shared.io2Main())
                    .subscribe(onNext: { [weak self] user in
                        guard let sf = self else {
                            return
                        }
                        sf.updateUserInfo(user: user, sessionMember: nil)
                    }).disposed(by: disposeBag)
                return 
            }
            if let info = sender.syncGetSessionMemberInfo(fromUId!) {
                self.updateUserInfo(user: info.0, sessionMember: info.1)
            }
        } else {
            self.cellWrapper.avatarView()?.isHidden = true
        }
    }
    
    open func initBubble() {
        let fromUId = self.message?.fromUId
        if (self.hasBubble() && fromUId != nil) {
            let position = cellPosition()
            var image: UIImage? = nil
            if (position == IMMsgPosType.Left.rawValue) {
                image = Bubble().drawRectWithRoundedCorner(
                    radius: 8, borderWidth: 0, backgroundColor: UIColor.init(hex: "EEEEEE"),
                    borderColor: UIColor.init(hex: "EEEEEE"), width: 40, height: 40, pos: 0)
            } else if (position == IMMsgPosType.Right.rawValue) {
                image = Bubble().drawRectWithRoundedCorner(
                    radius: 8, borderWidth: 0, backgroundColor: UIColor.init(hex: "ffd1e3fe"),
                    borderColor: UIColor.init(hex: "ffd1e3fe"), width: 40, height: 40, pos: 0)
            } else {
                image = Bubble().drawRectWithRoundedCorner(
                    radius: 8, borderWidth: 0, backgroundColor: UIColor.init(hex: "40000000"),
                    borderColor: UIColor.init(hex: "20000000"), width: 40, height: 24, pos: 0)
            }
            updateUserBubble(image: image)
        } else {
            updateUserBubble(image: nil)
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func msgView() -> IMsgBodyView {
        return IMUnSupportMsgView()
    }
    
    private func updateUserInfo(user: User, sessionMember: SessionMember?) {
        var showNickname = IMUIManager.shared.nicknameForSessionMember(user, sessionMember)
        if sessionMember?.deleted == 1 {
            showNickname += "(已退出)"
        }
        self.cellWrapper.nickView()?.text = showNickname
        if let avatar = IMUIManager.shared.avatarForSessionMember(user, sessionMember) {
            if avatar.length > 0 {
                self.cellWrapper.avatarView()?.renderImageByUrlWithCorner(url: avatar, radius: 10)
                self.cellWrapper.avatarView()?.isHidden = false
                return
            }
        }
        self.renderProviderAvatar(user: user)
    }
    
    private func renderProviderAvatar(user: User) {
        let image = IMUIManager.shared.uiResourceProvider?.avatar(user: user)
        self.cellWrapper.avatarView()?.image = image
        self.cellWrapper.avatarView()?.isHidden = false
    }
    
    private func updateUserBubble(image: UIImage?) {
        self.bubbleView.image = image
    }
    
    open func initMessageStatus() {
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
            if self.message?.fromUId == IMCoreManager.shared.uId {
                self.queryReadStatus()
            }
            break
        }
    }
    
    private func queryReadStatus() {
        guard let session = self.session else {
            return
        }
        if session.type == SessionType.MsgRecord.rawValue || session.type == SessionType.SuperGroup.rawValue {
            return
        }
        if session.functionFlag & IMChatFunction.Read.rawValue == 0 {
            return
        }
        Observable.just(session.id).flatMap { sessionId in
            let count = IMCoreManager.shared.database.sessionMemberDao().findSessionMemberCount(sessionId)
            return Observable.just(count)
        }.compose(RxTransformer.shared.io2Main())
            .subscribe(onNext: { [weak self] count in
                self?.showReadStatus(count)
            }).disposed(by: self.disposeBag)
    }
    
    private func showReadStatus(_ count: Int) {
        guard let message = self.message else {
            return
        }
        let readUIds = message.getReadUIds()
        let realCount = max(count-1, 1)
        let progress = CGFloat(readUIds.count)/CGFloat(realCount)
        self.cellWrapper.readStatusView()?.isHidden = false
        self.cellWrapper.readStatusView()?.updateStatus(UIColor.init(hex: "#17a121"), 4, progress)
    }
    
    open override func appear() {
        self.cellWrapper.appear()
        self.onMessageShow()
        self.msgView().onViewAppear()
    }
    
    open override func disappear() {
        self.cellWrapper.disAppear()
        self.msgView().onViewDisappear()
    }
    
    open func hasBubble() -> Bool {
        guard let msg = self.message else {
            return false
        }
        return IMUIManager.shared.getMsgCellProvider(msg.type).hasBubble()
    }
    
    open func canSelected() -> Bool {
        guard let msg = self.message else {
            return false
        }
        return IMUIManager.shared.getMsgCellProvider(msg.type).canSelected()
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
        if cellWrapper is IMMsgLeftCellWrapper {
            return IMMsgPosType.Left.rawValue
        } else if cellWrapper is IMMsgRightCellWrapper {
            return IMMsgPosType.Right.rawValue
        }
        return IMMsgPosType.Mid.rawValue
    }
    
    open func onMessageShow() {
        if (message == nil) {
            return
        }
        if (message!.msgId <= 0 || message!.fromUId == IMCoreManager.shared.uId) {
            return
        }
        if (message!.operateStatus & MsgOperateStatus.ClientRead.rawValue) > 0
                && ((message!.operateStatus & MsgOperateStatus.ServerRead.rawValue) > 0
            ) {
            return
        }
        self.delegate?.msgSender()?.readMessage(message!)
    }
    
    open func highlightFlashing(_ times: Int) {
        if (times == 0) {
            return
        }
        if (times%2 == 0) {
            self.backgroundColor = UIColor.init(hex: "#2008AAFF")
        } else {
            self.backgroundColor = UIColor.clear
        }
        DispatchQueue.main.asyncAfter(deadline: .now()+0.35, execute: { [weak self] in
            self?.highlightFlashing(times - 1)
        })
    }
}
