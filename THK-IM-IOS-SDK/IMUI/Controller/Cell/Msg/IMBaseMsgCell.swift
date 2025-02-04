//
//  IMBaseMsgCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/28.
//

import CocoaLumberjack
import Foundation
import Kingfisher
import RxCocoa
import RxGesture
import RxSwift
import UIKit

open class IMBaseMsgCell: IMBaseTableCell {

    open weak var delegate: IMMsgCellOperator? = nil
    open var msgBodyView: IMsgBodyView
    open var replyView = IMMsgReplyView()
    open var messageType = 0
    open var cellWrapper: IMMsgCellWrapper
    open var message: Message? = nil
    open var session: Session? = nil
    open var position: Int? = nil

    public init(_ reuseIdentifier: String, _ messageType: Int, _ wrapper: IMMsgCellWrapper) {
        self.cellWrapper = wrapper
        self.messageType = messageType
        var cellPosition = IMMsgPosType.Left
        if self.cellWrapper is IMMsgLeftCellWrapper {
            cellPosition = IMMsgPosType.Left
        } else if self.cellWrapper is IMMsgMiddleCellWrapper {
            cellPosition = IMMsgPosType.Mid
        } else if self.cellWrapper is IMMsgRightCellWrapper {
            cellPosition = IMMsgPosType.Right
        }
        self.msgBodyView = IMUIManager.shared.getMsgCellProvider(messageType).msgBodyView(
            cellPosition)
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        self.tintColor = IMUIManager.shared.uiResourceProvider?.tintColor()
        self.backgroundColor = UIColor.clear
        self.cellWrapper.attach(contentView)
        self.cellWrapper.layoutSubViews(self.isEditing)
        self.cellWrapper.containerView.addSubview(self.replyView)
        self.cellWrapper.containerView.addSubview(self.msgBodyView.contentView())
        self.setupEvent()
    }

    func setupEvent() {
        self.replyView.rx.tapGesture(configuration: { gestureRecognizer, delegate in
            delegate.otherFailureRequirementPolicy = .custom {
                gestureRecognizer, otherGestureRecognizer in
                return otherGestureRecognizer is UILongPressGestureRecognizer
            }
        })
        .when(.ended)
        .subscribe(onNext: { [weak self] _ in
            guard let sf = self else {
                return
            }
            guard let referMsg = sf.message?.referMsg else {
                return
            }
            sf.delegate?.onMsgReferContentClick(message: referMsg, view: sf.replyView)
        })
        .disposed(by: disposeBag)

        let msgView = self.msgBodyView.contentView()
        // 点击事件
        msgView.rx.tapGesture(configuration: { gestureRecognizer, delegate in
            delegate.otherFailureRequirementPolicy = .custom {
                gestureRecognizer, otherGestureRecognizer in
                return otherGestureRecognizer is UILongPressGestureRecognizer
            }
        })
        .when(.ended)
        .subscribe(onNext: { [weak self] _ in
            self?.delegate?.onMsgCellClick(
                message: (self?.message)!,
                position: self?.position ?? 0,
                view: (self?.msgBodyView.contentView())!
            )
        })
        .disposed(by: disposeBag)

        // 长按事件
        self.cellWrapper.containerView.rx.longPressGesture()
            .when(.began)
            .subscribe(onNext: { [weak self] _ in
                guard let sf = self else {
                    return
                }
                if !sf.canSelected() {
                    return
                }
                sf.delegate?.onMsgCellLongClick(
                    message: (sf.message)!,
                    position: sf.position ?? 0,
                    view: sf.msgBodyView.contentView()
                )
            })
            .disposed(by: disposeBag)
        let resendButton = self.cellWrapper.resendButton()
        if resendButton != nil {
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
            delegate.otherFailureRequirementPolicy = .custom {
                gestureRecognizer, otherGestureRecognizer in
                return otherGestureRecognizer is UILongPressGestureRecognizer
            }
        })
        .when(.ended)
        .subscribe(onNext: { [weak self] _ in
            self?.delegate?.onMsgSenderClick(
                message: (self?.message)!,
                position: self?.position ?? 0,
                view: (self?.cellWrapper.avatarView())!
            )
        }).disposed(by: disposeBag)

        avatarView?.rx.longPressGesture()
            .when(.began)
            .subscribe(onNext: { [weak self] _ in
                self?.delegate?.onMsgSenderLongClick(
                    message: (self?.message)!,
                    position: self?.position ?? 0,
                    view: (self?.msgBodyView.contentView())!
                )
            })
            .disposed(by: disposeBag)
        if let readStatusView = self.cellWrapper.readStatusView() {
            readStatusView.rx.tapGesture(configuration: { [weak self] gestureRecognizer, delegate in
                delegate.touchReceptionPolicy = .custom { gestureRecognizer, touches in
                    return touches.view == self?.cellWrapper.readStatusView()
                }
                delegate.otherFailureRequirementPolicy = .custom {
                    gestureRecognizer, otherGestureRecognizer in
                    return otherGestureRecognizer is UILongPressGestureRecognizer
                }
            })
            .when(.ended)
            .subscribe(onNext: { [weak self] _ in
                self?.delegate?.onMsgReadStatusClick(message: (self?.message)!)
            }).disposed(by: self.disposeBag)
        }
    }

    open func setMessage(
        _ position: Int, _ messages: [Message], _ session: Session, _ delegate: IMMsgCellOperator
    ) {
        self.message = messages[position]
        self.position = position
        self.session = session
        self.layoutMessageView()
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        //        self.initChecked()
        self.cellWrapper.layoutSubViews(self.isEditing)
    }

    private func initChecked() {
        if let editControlClass = NSClassFromString("UITableViewCellEditControl") {
            for subview in self.subviews {
                if subview.isMember(of: editControlClass) {
                    for v in subview.subviews {
                        if v is UIImageView {
                            if let imageView = (v as? UIImageView) {
                                if self.isSelected {
                                    imageView.image = ResourceUtils.loadImage(
                                        named: "ic_message_checked")
                                } else {
                                    imageView.image = ResourceUtils.loadImage(
                                        named: "ic_message_unchecked")
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    func layoutMessageView() {
        self.initUser()
        self.initBubble()
        self.initMsgContent()
        self.initMessageStatus()
    }

    open func initMsgContent() {
        if let referMsg = self.message?.referMsg {
            self.replyView.setRelyContent(referMsg, self.session, self.delegate)
        } else {
            self.replyView.clearReplyContent()
        }
        let msgView = self.msgBodyView.contentView()
        msgView.snp.remakeConstraints { make in
            make.top.equalTo(self.replyView.snp.bottom).offset(2)
            make.left.equalToSuperview().offset(2)
            make.right.lessThanOrEqualToSuperview().offset(-2)
            make.bottom.equalToSuperview().offset(-2)
        }
        if let msg = self.message {
            self.msgBodyView.setMessage(msg, self.session, self.delegate)
        }
    }

    open func initUser() {
        let fromUId = self.message?.fromUId
        if self.showAvatar() && fromUId != nil && self.cellWrapper.avatarView() != nil {
            guard let delegate = self.delegate else {
                return
            }
            if let sender = delegate.msgSender() {
                if let info = sender.syncGetSessionMemberInfo(fromUId!) {
                    self.updateUserInfo(user: info.0, sessionMember: info.1)
                }
            } else {
                IMCoreManager.shared.userModule
                    .queryUser(id: fromUId!)
                    .compose(RxTransformer.shared.io2Main())
                    .subscribe(onNext: { [weak self] user in
                        guard let sf = self else {
                            return
                        }
                        sf.updateUserInfo(user: user, sessionMember: nil)
                    }).disposed(by: disposeBag)
            }

        } else {
            self.cellWrapper.avatarView()?.isHidden = true
        }
    }

    open func initBubble() {
        guard let message = self.message else { return }
        if self.hasBubble() {
            let position = cellPosition()
            var image: UIImage? = nil
            if position == IMMsgPosType.Left.rawValue {
                image = IMUIManager.shared.uiResourceProvider?.msgBubble(
                    message: message, session: self.session)
                if image == nil {
                    image = Bubble().drawRectWithRoundedCorner(
                        radius: 8, borderWidth: 0, backgroundColor: UIColor.init(hex: "E5E5E5"),
                        borderColor: UIColor.init(hex: "E5E5E5"), width: 40, height: 40, pos: 0)
                }
            } else if position == IMMsgPosType.Right.rawValue {
                image = IMUIManager.shared.uiResourceProvider?.msgBubble(
                    message: message, session: self.session)
                if image == nil {
                    image = Bubble().drawRectWithRoundedCorner(
                        radius: 8, borderWidth: 0, backgroundColor: UIColor.init(hex: "ffd1e3fe"),
                        borderColor: UIColor.init(hex: "ffd1e3fe"), width: 40, height: 40, pos: 0)
                }
            } else {
                image = IMUIManager.shared.uiResourceProvider?.msgBubble(
                    message: message, session: self.session)
                if image == nil {
                    image = Bubble().drawRectWithRoundedCorner(
                        radius: 8, borderWidth: 0, backgroundColor: UIColor.init(hex: "BBBBBB"),
                        borderColor: UIColor.init(hex: "BBBBBB"), width: 40, height: 24, pos: 0)
                }
            }
            self.updateUserBubble(image: image)
        } else {
            self.updateUserBubble(image: nil)
        }
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateUserInfo(user: User, sessionMember: SessionMember?) {
        var showNickname = IMUIManager.shared.nicknameForSessionMember(user, sessionMember)
        if sessionMember?.deleted == 1 {
            showNickname += ResourceUtils.loadString("had_exited")
        }
        self.cellWrapper.nickView()?.text = showNickname
        if let avatar = IMUIManager.shared.avatarForSessionMember(user, sessionMember) {
            if avatar.length > 0 {
                self.cellWrapper.avatarView()?.renderImageByUrlWithCorner(
                    url: avatar, radius: CGFloat(IMUIManager.shared.msgCellAvatarWidth / 2))
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
        self.cellWrapper.bubbleView.image = image
    }

    open func initMessageStatus() {
        guard let message = self.message else {
            return
        }
        switch message.sendStatus {
        case MsgSendStatus.Init.rawValue, MsgSendStatus.Uploading.rawValue,
            MsgSendStatus.Sending.rawValue:
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
        if session.type == SessionType.MsgRecord.rawValue
            || session.type == SessionType.SuperGroup.rawValue
        {
            return
        }
        let supportRead =
            IMUIManager.shared.uiResourceProvider?.supportFunction(
                session, IMChatFunction.Read.rawValue) ?? false
        if !supportRead {
            return
        }
        Observable.just(session.id).flatMap { sessionId in
            let count = IMCoreManager.shared.database.sessionMemberDao().findSessionMemberCount(
                sessionId)
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
        let realCount = max(count - 1, 1)
        let progress = CGFloat(readUIds.count) / CGFloat(realCount)
        self.cellWrapper.readStatusView()?.isHidden = false
        let statusColor =
            IMUIManager.shared.uiResourceProvider?.tintColor() ?? UIColor.init(hex: "#17a121")
        self.cellWrapper.readStatusView()?.updateStatus(statusColor, 4, progress)
    }

    open override func appear() {
        self.cellWrapper.appear()
        self.onMessageShow()
        self.msgBodyView.onViewAppear()
        self.replyView.onViewAppear()
    }

    open override func disappear() {
        self.cellWrapper.disAppear()
        self.msgBodyView.onViewDisappear()
        self.replyView.onViewDisappear()
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
        if message == nil {
            return
        }
        if message!.msgId <= 0 || message!.fromUId == IMCoreManager.shared.uId {
            return
        }
        if (message!.operateStatus & MsgOperateStatus.ClientRead.rawValue) > 0
            && ((message!.operateStatus & MsgOperateStatus.ServerRead.rawValue) > 0)
        {
            return
        }
        self.delegate?.msgSender()?.readMessage(message!)
    }

    open func highlightFlashing(_ times: Int) {
        if times == 0 {
            return
        }
        if times % 2 == 0 {
            self.backgroundColor = IMUIManager.shared.uiResourceProvider?.tintColor()?
                .withAlphaComponent(0.12)
        } else {
            self.backgroundColor = UIColor.clear
        }
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.35,
            execute: { [weak self] in
                self?.highlightFlashing(times - 1)
            })
    }
}
