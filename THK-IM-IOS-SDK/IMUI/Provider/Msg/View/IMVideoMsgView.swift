//
//  IMVideoMsgView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/2/24.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit
import CocoaLumberjack


class IMVideoMsgView: UIImageView, IMsgBodyView {
    
    private let durationLabel = IMMsgLabelView()
    private let playView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.durationLabel.font = UIFont.systemFont(ofSize: 10)
        self.durationLabel.textColor = UIColor.white
        self.durationLabel.layer.backgroundColor = UIColor.init(hex: "333333").withAlphaComponent(0.5).cgColor
        self.durationLabel.layer.cornerRadius = 6
        self.durationLabel.padding = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        self.addSubview(self.durationLabel)
        
        self.playView.image = UIImage(named: "icon_video_play")
        self.addSubview(self.playView)
    }
    
    
    func setMessage(_ message: Message, _ session: Session?, _ delegate: IMMsgCellOperator?, _ isReply: Bool = false) {
        let provider = IMUIManager.shared.getMsgCellProvider(message.type)
        let size = isReply ? provider.replyMsgViewSize(message, session) : provider.viewSize(message, session)
        self.removeConstraints(self.constraints)
        self.isHidden = true
        self.snp.makeConstraints { make in
            make.width.equalTo(size.width)
            make.height.equalTo(size.height)
        }
        self.durationLabel.snp.remakeConstraints { make in
            make.bottom.equalToSuperview().offset(-5)
            make.right.equalToSuperview().offset(-5)
            make.height.equalTo(20)
        }
        if isReply {
            self.durationLabel.isHidden = true
        }
        self.playView.snp.remakeConstraints { make in
            make.center.equalToSuperview()
            if isReply {
                make.size.equalTo(10)
            } else {
                make.size.equalTo(40)
            }
        }
        if (message.data != nil) {
            do {
                let data = try JSONDecoder().decode(
                    IMVideoMsgData.self,
                    from: message.data!.data(using: .utf8) ?? Data())
                if (data.duration != nil) {
                    self.durationLabel.text = DateUtils.secondToDuration(seconds: data.duration!)
                }
                if (data.thumbnailPath != nil) {
                    let path = IMCoreManager.shared.storageModule.sandboxFilePath(data.thumbnailPath!)
                    self.renderImageByPathWithCorner(path: path, radius: 8.0)
                    self.isHidden = false
                }
            } catch {
                DDLogError("\(error)")
            }
            return
        }
    
        if (message.content != nil) {
            do {
                let body = try JSONDecoder().decode(
                    IMVideoMsgBody.self,
                    from: message.content!.data(using: .utf8) ?? Data())
                if (body.duration != nil) {
                    self.durationLabel.text = DateUtils.secondToDuration(seconds: body.duration!)
                }
                if (body.thumbnailUrl != nil) {
                    _ = IMCoreManager.shared.messageModule.getMsgProcessor(message.type)
                        .downloadMsgContent(message, resourceType: IMMsgResourceType.Thumbnail.rawValue)
                }
            } catch {
                DDLogError("\(error)")
            }
        }
    }
    
    func contentView() -> UIView {
        return self
    }
}
