//
//  IMBaseSessionCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/28.
//

import Foundation
import UIKit
import Kingfisher
import CocoaLumberjack
import BadgeSwift
import RxSwift

open class IMBaseSessionCell : IMBaseTableCell {
    
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
    
    public lazy var msgView: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 12)
        view.textColor = UIColor.gray
        return view
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
    
    deinit {
        DDLogDebug("BaseSessionCell deinit")
    }
    
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        DDLogDebug("BaseSessionCell init")
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        contentView.addSubview(self.avatarView)
        contentView.addSubview(self.nickView)
        contentView.addSubview(self.msgView)
        contentView.addSubview(self.lastTimeView)
        contentView.addSubview(self.unreadCountView)
        contentView.addSubview(self.silenceView)
        
        avatarView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
            make.width.equalTo(42)
            make.height.equalTo(42)
        }
        nickView.snp.makeConstraints { [weak self] make in
            guard let sf = self else {
                return
            }
            make.top.equalToSuperview().offset(10)
            make.left.equalTo(sf.avatarView.snp.right).offset(5)
            make.right.equalTo(sf.lastTimeView.snp.left).offset(-5)
        }
        msgView.snp.makeConstraints { [weak self] make in
            guard let sf = self else {
                return
            }
            make.top.equalTo(sf.nickView.snp.bottom).offset(10)
            make.left.equalTo(sf.avatarView.snp.right).offset(5)
            make.right.equalTo(sf.lastTimeView.snp.left).offset(-5)
        }
        lastTimeView.snp.makeConstraints {  [weak self] make in
            guard let sf = self else {
                return
            }
            make.top.equalToSuperview().offset(10)
            make.right.equalTo(sf.contentView.snp.right).offset(-10)
            make.width.lessThanOrEqualTo(120)
        }
        unreadCountView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.left.equalToSuperview().offset(42)
            make.height.equalTo(16)
            make.width.greaterThanOrEqualTo(16)
        }
        silenceView.snp.makeConstraints { make in
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
        self.showSessionEntityInfo(session)
        self.updateSession(session)
    }
    
    public func updateSession(_ session: Session) {
        self.msgView.text = session.lastMsg
        let dateString = DateUtils.timeToMsgTime(ms: session.mTime, now: IMCoreManager.shared.severTime)
        self.lastTimeView.text = dateString
        self.lastTimeView.textAlignment = .right
        let number = String.getNumber(count: Int(session.unreadCount))
        if (number != nil) {
            unreadCountView.text = number
            unreadCountView.isHidden = false
        } else {
            unreadCountView.text = ""
            unreadCountView.isHidden = true
        }
        if (session.status & SessionStatus.Silence.rawValue > 0) {
            silenceView.image = ResourceUtils.loadImage(named: "icon_msg_silence")
            unreadCountView.badgeColor  = .lightGray
        } else {
            silenceView.image = nil
            unreadCountView.badgeColor  = .red
        }
        if (session.topTimestamp > 0) {
            self.contentView.backgroundColor = UIColor.init(hex: "#EEEEEE")
        } else {
            self.contentView.backgroundColor = .clear
        }
    }
    
    open func showSessionEntityInfo(_ session: Session) {
        
    }
    
}
