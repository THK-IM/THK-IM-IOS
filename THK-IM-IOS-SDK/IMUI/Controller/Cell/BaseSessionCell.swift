//
//  IMSessionCellView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/28.
//

import Foundation
import UIKit
import Kingfisher
import CocoaLumberjack

open class BaseSessionCell : BaseCell {
    
    lazy var avatarView: UIImageView = {
        let view = UIImageView()
        return view
    }()
    
    lazy var nickView: UILabel = {
        let view = UILabel()
        view.font = UIFont.boldSystemFont(ofSize: 14)
        view.numberOfLines = 1
        return view
    }()
    
    lazy var msgView: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 12)
        view.textColor = UIColor.gray
        return view
    }()
    
    lazy var timeView: UILabel = {
        let view = UILabel()
        view.font = UIFont.systemFont(ofSize: 10)
        view.textColor = UIColor.gray
        view.numberOfLines = 1
        return view
    }()
    
    deinit {
        DDLogDebug("BaseSessionCell deinit")
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        DDLogDebug("BaseSessionCell init")
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(self.avatarView)
        contentView.addSubview(self.nickView)
        contentView.addSubview(self.msgView)
        contentView.addSubview(self.timeView)
        
        avatarView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.left.equalToSuperview().offset(10)
            make.size.equalTo(42)
        }
        nickView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.left.equalTo(avatarView.snp.right).offset(5)
            make.right.equalTo(timeView.snp.left).offset(-5)
        }
        msgView.snp.makeConstraints { make in
            make.top.equalTo(self.nickView.snp.bottom).offset(10)
            make.left.equalTo(avatarView.snp.right).offset(5)
            make.right.equalTo(timeView.snp.left).offset(-5)
        }
        timeView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.right.equalTo(contentView.snp.right).offset(-10)
            make.width.lessThanOrEqualTo(120)
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
    
    func setSession(_ session: Session) {
        self.avatarView.ca_setImageUrlWithCorner(url: "https://picsum.photos/300/300", radius: 20)
        self.nickView.text = String(format: "nick-%d", session.entityId)
        self.msgView.text = session.lastMsg
        let dateString = Date().timeToDateString(showTime: session.mTime, currentTime: IMManager.shared.severTime)
        self.timeView.text = dateString
        self.timeView.textAlignment = .right
    }
    
}
