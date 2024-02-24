//
//  IMImageMsgView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/2/24.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit
import CocoaLumberjack

class IMImageMsgView: UIImageView, BaseMsgView {
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.contentMode = .scaleAspectFit
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
        if (message.data != nil) {
            do {
                let data = try JSONDecoder().decode(
                    IMImageMsgData.self,
                    from: message.data!.data(using: .utf8) ?? Data())
                if (data.thumbnailPath != nil) {
                    let path = IMCoreManager.shared.storageModule.sandboxFilePath(data.thumbnailPath!)
                    self.ca_setImagePathWithCorner(path: path, radius: 8.0)
                    self.isHidden = false
                }
            } catch {
                DDLogDebug("\(error)")
            }
            return
        }
        
        if (message.content != nil) {
            do {
                let body = try JSONDecoder().decode(
                    IMImageMsgBody.self,
                    from: message.content!.data(using: .utf8) ?? Data())
                if (body.thumbnailUrl != nil) {
                    _ = IMCoreManager.shared.messageModule.getMsgProcessor(message.type)
                        .downloadMsgContent(message, resourceType: IMMsgResourceType.Thumbnail.rawValue)
                }
            } catch {
                DDLogDebug("\(error)")
            }
        }
    }
}
