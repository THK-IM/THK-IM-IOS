//
//  IMImageMsgView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/2/24.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit
import CocoaLumberjack

class IMImageMsgView: UIImageView, IMsgBodyView {
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.backgroundColor = .black
        self.contentMode = .scaleAspectFill
    }
    
    func setMessage(_ message: Message, _ session: Session?, _ delegate: IMMsgCellOperator?, _ isReply: Bool = false) {
        self.resetlayout(message, isReply)
        self.showMessage(message)
    }
    
    private func resetlayout(_ message: Message, _ isReply: Bool) {
        var size = self.viewSize(message)
        if (isReply) {
            size = CGSize(width: size.width * 0.25, height: size.height * 0.25)
        }
        self.isHidden = true
        self.snp.makeConstraints { make in
            make.width.equalTo(size.width)
            make.height.equalTo(size.height)
        }
    }
    
    private func viewSize(_ message: Message) -> CGSize {
        var width = 100.0
        var height = 100.0
        do {
            if (message.data != nil) {
                let data = try JSONDecoder().decode(
                    IMImageMsgData.self,
                    from: message.data!.data(using: .utf8) ?? Data())
                if data.height != nil && data.width != nil {
                    width = Double(data.width!).ptValue()
                    height = Double(data.height!).ptValue()
                }
            }
            if (message.content != nil) {
                let body = try JSONDecoder().decode(
                    IMImageMsgBody.self,
                    from: message.content!.data(using: .utf8) ?? Data())
                if body.height != nil && body.width != nil {
                    width = Double(body.width!).ptValue()
                    height = Double(body.height!).ptValue()
                }
            }
            if (width >= height) {
                let calWidth = max(80, min(200, width))
                let calHeight = max(80, calWidth * height / width)
                return CGSize(width: calWidth, height: calHeight)
            } else  {
                let calHeight = max(80, min(200, height))
                let calWidth = max(80, calHeight * width / height)
                return CGSize(width: calWidth, height: calHeight)
            }
        } catch {
            DDLogError("\(error)")
            return CGSize(width: width, height: 1.5 * width)
        }
    }
    
    private func showMessage(_ message: Message) {
        if (message.data != nil) {
            do {
                let data = try JSONDecoder().decode(
                    IMImageMsgData.self,
                    from: message.data!.data(using: .utf8) ?? Data())
                if (data.thumbnailPath != nil) {
                    let path = IMCoreManager.shared.storageModule.sandboxFilePath(data.thumbnailPath!)
                    self.renderImageByPathWithCorner(path: path, radius: 8.0)
                    self.isHidden = false
                    return
                }
            } catch {
                DDLogDebug("\(error)")
            }
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
    
    
    
    func contentView() -> UIView {
        return self
    }
}
