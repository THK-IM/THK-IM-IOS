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
import SwiftEventBus

class IMImageMsgCell: BaseMsgCell {
    
    private let view: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleToFill
        return v
    }()
    private var taskId: String?
    private var downloadListener: FileLoaderListener?
    
    override func msgView() -> UIView {
        return self.view
    }
    
    override func setMessage(_ msgs: Array<Message>, _ position: Int) {
        super.setMessage(msgs, position)
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
        if (msg.data != nil) {
            do {
                let data = try JSONDecoder().decode(
                    IMImageMsgData.self,
                    from: msg.data!.data(using: .utf8) ?? Data())
                if (data.thumbnailPath != nil) {
                    self.view.isHidden = false
                    let path = IMCoreManager.shared.storageModule.sandboxFilePath(data.thumbnailPath!)
                    self.view.ca_setImagePathWithCorner(path: path, radius: 8.0)
                    return
                }
            } catch {
                DDLogError(error)
            }
        }
        
        if (msg.content != nil) {
            do {
                let body = try JSONDecoder().decode(
                    IMImageMsgBody.self,
                    from: msg.content!.data(using: .utf8) ?? Data())
                if (body.thumbnailUrl != nil) {
                    IMCoreManager.shared.getMessageModule().getMsgProcessor(msg.type)
                        .downloadMsgContent(msg, resourceType: IMMsgResourceType.Thumbnail.rawValue)
                }
            } catch {
                DDLogError(error)
            }
        }

    }
    
    override func disappear() {
        super.disappear()
        self.unregister()
    }
    
    private func unregister() {
    }
    
}
