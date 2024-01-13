//
//  IMImageCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/10.
//

import Foundation
import UIKit
import CocoaLumberjack
import Kingfisher

class IMImageMsgCell: BaseMsgCell {
    
    private let view: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleToFill
        return v
    }()
    
    override func msgView() -> UIView {
        return self.view
    }
    
    open override func setMessage(_ position: Int, _ messages: Array<Message>, _ session: Session, _ delegate: IMMsgCellOperator) {
        super.setMessage(position, messages, session, delegate)
        guard let msg = self.message else {
            return
        }
        self.view.isHidden = true
        let size = IMUIManager.shared.getMsgCellProvider(msg.type).viewSize(msg, session)
        self.view.removeConstraints(self.view.constraints)
        self.view.snp.makeConstraints { make in
            make.width.equalTo(size.width)
            make.height.equalTo(size.height)
        }
        if (msg.data != nil) {
            do {
                let data = try JSONDecoder().decode(
                    IMImageMsgData.self,
                    from: msg.data!.data(using: .utf8) ?? Data())
                if (data.thumbnailPath != nil) {
                    let path = IMCoreManager.shared.storageModule.sandboxFilePath(data.thumbnailPath!)
                    self.view.ca_setImagePathWithCorner(path: path, radius: 8.0)
                    self.view.isHidden = false
                }
            } catch {
                DDLogDebug("\(error)")
            }
            return
        }
        
        if (msg.content != nil) {
            do {
                let body = try JSONDecoder().decode(
                    IMImageMsgBody.self,
                    from: msg.content!.data(using: .utf8) ?? Data())
                if (body.thumbnailUrl != nil) {
                    _ = IMCoreManager.shared.messageModule.getMsgProcessor(msg.type)
                        .downloadMsgContent(msg, resourceType: IMMsgResourceType.Thumbnail.rawValue)
                }
            } catch {
                DDLogDebug("\(error)")
            }
        }

    }
    
}
