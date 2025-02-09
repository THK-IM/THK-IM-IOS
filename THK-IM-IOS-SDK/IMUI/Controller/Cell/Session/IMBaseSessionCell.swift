//
//  IMBaseSessionCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/28.
//

import BadgeSwift
import CocoaLumberjack
import Foundation
import Kingfisher
import RxSwift
import UIKit

open class IMBaseSessionCell: IMBaseTableCell {

    public lazy var unreadCountView: BadgeSwift = {
        let view = BadgeSwift()
        view.font = UIFont.systemFont(ofSize: 10)
        view.textColor = UIColor.white
        view.badgeColor = UIColor.red
        view.cornerRadius = 8
        return view
    }()

    public lazy var avatarView: UIImageView = {
        let view = UIImageView()
        return view
    }()

    public lazy var nickView: UILabel = {
        let view = UILabel()
        view.font = UIFont.boldSystemFont(ofSize: 14)
        view.numberOfLines = 1
        return view
    }()

    public lazy var senderStatusView: UIImageView = {
        let v = UIImageView()
        return v
    }()

    public lazy var atInfoView: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 12)
        view.textColor = UIColor.red
        view.numberOfLines = 1
        return view
    }()

    public lazy var senderView: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 12)
        view.textColor = UIColor.gray
        view.numberOfLines = 1
        return view
    }()

    public lazy var msgView: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 12)
        view.textColor = UIColor.gray
        view.numberOfLines = 1
        return view
    }()

    public lazy var msgLayout: UIView = {
        let v = UIView()
        v.addSubview(self.senderStatusView)
        v.addSubview(self.atInfoView)
        v.addSubview(self.senderView)
        v.addSubview(self.msgView)

        self.senderStatusView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview()
            make.size.equalTo(0)
        }

        self.atInfoView.snp.makeConstraints { make in
            make.left.equalTo(self.senderStatusView.snp.right).offset(4)
            make.centerY.equalToSuperview()
        }

        self.senderView.snp.makeConstraints { make in
            make.left.equalTo(self.atInfoView.snp.right)
            make.centerY.equalToSuperview()
        }

        self.msgView.snp.makeConstraints { make in
            make.left.equalTo(self.senderView.snp.right)
            make.right.lessThanOrEqualToSuperview()
            make.centerY.equalToSuperview()
        }

        return v
    }()

    public lazy var lastTimeView: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 10)
        view.textColor = UIColor.gray
        view.numberOfLines = 1
        return view
    }()

    public lazy var silenceView: UIImageView = {
        let view = UIImageView()
        return view
    }()

    public var session: Session? = nil

    deinit {
        DDLogDebug("BaseSessionCell deinit")
    }

    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        DDLogDebug("BaseSessionCell init")
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        self.addSubviews()
        self.layoutAddedSubviews()
    }
    
    open func addSubviews() {
        self.contentView.addSubview(self.avatarView)
        self.contentView.addSubview(self.nickView)
        self.contentView.addSubview(self.msgLayout)
        self.contentView.addSubview(self.lastTimeView)
        self.contentView.addSubview(self.unreadCountView)
        self.contentView.addSubview(self.silenceView)
    }
    
    open func layoutAddedSubviews() {
        self.avatarView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
            make.width.equalTo(42)
            make.height.equalTo(42)
        }
        self.nickView.snp.makeConstraints { [weak self] make in
            guard let sf = self else {
                return
            }
            make.top.equalToSuperview().offset(10)
            make.left.equalTo(sf.avatarView.snp.right).offset(5)
            make.right.equalTo(sf.lastTimeView.snp.left).offset(-5)
        }
        self.msgLayout.snp.makeConstraints { [weak self] make in
            guard let sf = self else {
                return
            }
            make.top.equalTo(sf.nickView.snp.bottom).offset(10)
            make.bottom.equalToSuperview().offset(-8)
            make.left.equalTo(sf.avatarView.snp.right).offset(5)
            make.right.equalTo(sf.lastTimeView.snp.left).offset(-5)
        }
        self.lastTimeView.snp.makeConstraints { [weak self] make in
            guard let sf = self else {
                return
            }
            make.top.equalToSuperview().offset(10)
            make.right.equalTo(sf.contentView.snp.right).offset(-10)
            make.width.lessThanOrEqualTo(120)
        }
        self.unreadCountView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.left.equalToSuperview().offset(42)
            make.height.equalTo(16)
            make.width.greaterThanOrEqualTo(16)
        }
        self.silenceView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-8)
            make.bottom.equalToSuperview().offset(-8)
            make.height.equalTo(16)
            make.width.equalTo(16)
        }
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    open override func appear() {
        super.appear()
        DDLogDebug("IMSessionCellView display")
    }

    open override func disappear() {
        super.disappear()
        DDLogDebug("IMSessionCellView disappear")
    }

    public func setSession(_ session: Session) {
        self.updateSession(session)
    }

    open func updateSession(_ session: Session) {
        self.session = session
        self.renderSessionStatus()
        self.renderSessionEntityInfo()
        self.renderSessionMessage()
    }

    open func renderSessionEntityInfo() {
    }

    open func renderSessionStatus() {
        guard let session = self.session else { return }
        let dateString = DateUtils.timeToMsgTime(
            ms: session.mTime, now: IMCoreManager.shared.severTime)
        self.lastTimeView.text = dateString
        self.lastTimeView.textAlignment = .right
        let number = String.getNumber(count: Int(session.unreadCount))
        if number != nil {
            unreadCountView.text = number
            unreadCountView.isHidden = false
        } else {
            unreadCountView.text = ""
            unreadCountView.isHidden = true
        }
        if session.status & SessionStatus.Silence.rawValue > 0 {
            silenceView.image = ResourceUtils.loadImage(named: "icon_msg_silence")
            unreadCountView.badgeColor = .lightGray
        } else {
            silenceView.image = nil
            unreadCountView.badgeColor = .red
        }
        if session.topTimestamp > 0 {
            self.contentView.backgroundColor = UIColor.init(hex: "#EEEEEE")
        } else {
            self.contentView.backgroundColor = .clear
        }
    }

    open func renderSessionMessage() {
        if let session = self.session {
            let d = session.lastMsg?.data(using: .utf8) ?? Data()
            if let msg = try? JSONDecoder().decode(Message.self, from: d) {
                self.renderMessage(msg)
            } else {
                self.renderMessage(session.lastMsg)
            }
        } else {
            self.senderStatusView.image = nil
            self.senderStatusView.snp.updateConstraints { make in
                make.size.equalTo(0)
            }
            self.atInfoView.text = nil
        }
    }

    open func renderMessage(_ message: Message) {
        // 消息发送状态
        if message.sendStatus == MsgSendStatus.Failed.rawValue {
            self.senderStatusView.image = ResourceUtils.loadImage(named: "ic_msg_failed")
            self.senderStatusView.snp.updateConstraints { make in
                make.size.equalTo(16)
            }
        } else if message.sendStatus == MsgSendStatus.Success.rawValue {
            self.senderStatusView.image = nil
            self.senderStatusView.snp.updateConstraints { make in
                make.size.equalTo(0)
            }
        } else {
            self.senderStatusView.image = ResourceUtils.loadImage(named: "ic_sending")
            self.senderStatusView.snp.updateConstraints { make in
                make.size.equalTo(16)
            }
        }
        // @人视图
        if message.isAtMe()
            && (message.operateStatus & MsgOperateStatus.ClientRead.rawValue == 0)
        {
            self.atInfoView.text = ResourceUtils.loadString("someone_at_me")
        } else {
            self.atInfoView.text = nil
        }
        // 消息发件人姓名展示
        self.renderSenderName(message)
        // 消息内容展示
        if message.type == MsgType.Text.rawValue {
            if message.getAtUIds().isEmpty || message.content == nil {
                self.msgView.text = message.content
            } else {
                Observable.just(message).flatMap { msg in
                    let replaceContent = AtStringUtils.replaceAtUIdsToNickname(
                        msg.content!, msg.getAtUIds()
                    ) { id in
                        let name =
                            IMCoreManager.shared.messageModule.getMsgProcessor(msg.type)
                            .getUserSessionName(msg.sessionId, id) ?? ""
                        return name
                    }
                    return Observable.just(replaceContent)
                }.compose(RxTransformer.shared.io2Main())
                    .subscribe { [weak self] content in
                        self?.msgView.text = content
                    }.disposed(by: self.disposeBag)
            }
        } else {
            let msgDesc = IMCoreManager.shared.messageModule.getMsgProcessor(message.type)
                .msgDesc(msg: message)
            self.renderMessage(msgDesc)
        }
    }

    open func renderMessage(_ msg: String?) {
        self.senderStatusView.image = nil
        self.senderStatusView.snp.updateConstraints { make in
            make.size.equalTo(0)
        }
        self.atInfoView.text = nil
        self.msgView.text = msg
    }

    open func renderSenderName(_ message: Message) {
        if message.fromUId > 0 {
            Observable.just(message).flatMap { msg in
                let name =
                    IMCoreManager.shared.messageModule.getMsgProcessor(msg.type)
                    .getUserSessionName(msg.sessionId, msg.fromUId) ?? ""
                return Observable.just(name)
            }.compose(RxTransformer.shared.io2Main())
                .subscribe { [weak self] name in
                    if name.count > 0 {
                        self?.senderView.text = "\(name): "
                    } else {
                        self?.senderView.text = name
                    }
                } onError: { [weak self] err in
                    self?.senderView.text = nil
                }.disposed(by: self.disposeBag)
        }
    }

}
