//
//  IMVideoMsgCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/10.
//

import Foundation
import UIKit
import CocoaLumberjack
import Kingfisher

open class IMVideoMsgCell: BaseMsgCell {
    
    private lazy var view: UIImageView = {
        let view = UIImageView()
        durationLabel.font = UIFont.systemFont(ofSize: 10)
        durationLabel.textColor = UIColor.white
        durationLabel.layer.backgroundColor = UIColor.init(hex: "333333").withAlphaComponent(0.5).cgColor
        durationLabel.layer.cornerRadius = 6
        durationLabel.padding = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        view.addSubview(durationLabel)
        
        playView.image = UIImage(named: "icon_video_play")
        view.addSubview(playView)
        return view
    }()
    private let durationLabel = IMMsgLabelView()
    private let playView = UIImageView()
    
    open override func msgView() -> UIView {
        return self.view
    }
    
    open override func setMessage(_ mode: Int, _ position: Int, _ messages: Array<Message>, _ session: Session, _ delegate: IMMsgCellOperator) {
        super.setMessage(mode, position, messages, session, delegate)
        guard let msg = self.message else {
            return
        }
        self.view.isHidden = true
        let size = IMUIManager.shared.getMsgCellProvider(msg.type).viewSize(msg)
        self.view.removeConstraints(self.view.constraints)
        self.view.snp.makeConstraints { make in
            make.width.equalTo(size.width)
            make.height.equalTo(size.height)
        }
        self.durationLabel.snp.remakeConstraints { make in
            make.bottom.equalToSuperview().offset(-5)
            make.right.equalToSuperview().offset(-5)
            make.height.equalTo(20)
        }
        self.playView.snp.remakeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(40)
        }
        if (msg.data != nil) {
            do {
                let data = try JSONDecoder().decode(
                    IMVideoMsgData.self,
                    from: msg.data!.data(using: .utf8) ?? Data())
                if (data.duration != nil) {
                    self.durationLabel.text = DateUtils.secondToDuration(seconds: data.duration!)
                }
                if (data.thumbnailPath != nil) {
                    let path = IMCoreManager.shared.storageModule.sandboxFilePath(data.thumbnailPath!)
                    self.view.ca_setImagePathWithCorner(path: path, radius: 8.0)
                    self.view.isHidden = false
                }
            } catch {
                DDLogError(error)
            }
            return
        }
    
        if (msg.content != nil) {
            do {
                let body = try JSONDecoder().decode(
                    IMVideoMsgBody.self,
                    from: msg.content!.data(using: .utf8) ?? Data())
                if (body.duration != nil) {
                    self.durationLabel.text = DateUtils.secondToDuration(seconds: body.duration!)
                }
                if (body.thumbnailUrl != nil) {
                    _ = IMCoreManager.shared.getMessageModule().getMsgProcessor(msg.type)
                        .downloadMsgContent(msg, resourceType: IMMsgResourceType.Thumbnail.rawValue)
                }
            } catch {
                DDLogError(error)
            }
        }

    }
    
}

