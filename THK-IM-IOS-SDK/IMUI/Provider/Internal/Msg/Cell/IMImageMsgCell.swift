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
    
    private let view = UIImageView()
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
        DDLogDebug("IMImageMsgCell cell msg: \(msg.content)")
        do {
            let imageBody = try JSONDecoder().decode(
                ImageMsgBody.self,
                from: msg.content.data(using: .utf8) ?? Data())
            if (imageBody.width > imageBody.height) {
                var calWidth = min(200, imageBody.width)
                calWidth = max(80, calWidth)
                let calHeight = max(80, calWidth * imageBody.height / imageBody.width)
                self.view.removeConstraints(self.view.constraints)
                self.view.snp.makeConstraints { make in
                    make.width.equalTo(calWidth)
                    make.height.equalTo(calHeight)
                }
                DDLogDebug("IMImageMsgCell, id: \(msg.msgId),  \(calWidth) ,  \(calHeight) ")
            } else if (imageBody.height > imageBody.width) {
                var calHeight = min(200, imageBody.height)
                calHeight = max(80, calHeight)
                let calWidth = max(80, calHeight * imageBody.width / imageBody.height)
                self.view.removeConstraints(self.view.constraints)
                self.view.snp.makeConstraints { make in
                    make.width.equalTo(calWidth)
                    make.height.equalTo(calHeight)
                }
                DDLogDebug("IMImageMsgCell, id: \(msg.msgId),  \(calWidth) ,  \(calHeight) ")
            }
            
            if (imageBody.shrinkPath != nil) {
                // 每次debug运行时 document目录位置会改变，适配一下
                let path = IMCoreManager.shared.storageModule?.sandboxFilePath(imageBody.shrinkPath!)
                self.view.ca_setImagePathWithCorner(path: path!, radius: 8.0)
                return
            }
            if (imageBody.shrinkUrl != nil) {
                self.downloadShrinkImage(imageBody, msg)
            }
            self.view.image = nil
        } catch {
            DDLogError("IMImageMsgCell error: \(error)")
        }
    }
    
    func downloadShrinkImage(_ imageBody: ImageMsgBody, _ msg: Message) {
        guard let storageModule = IMCoreManager.shared.storageModule else {
            return
        }
        guard let fileModule = IMCoreManager.shared.fileLoadModule else {
            return
        }
        let filePaths = storageModule.getPathsFromFullPath(imageBody.shrinkUrl!)
        let path = storageModule.allocLocalFilePath(msg.sessionId, msg.fromUId, filePaths.1, "img")
        self.unregister()
        let downloadListener = FileLoaderListener(
            {
                [weak self] progress, state, url, path in
                switch state {
                case FileLoaderState.Success.rawValue:
                    do {
                        imageBody.shrinkPath = path
                        let d = try JSONEncoder().encode(imageBody)
                        guard let msg = self?.message else {
                            return
                        }
                        guard let content = String(data: d, encoding: .utf8) else {
                            return
                        }
                        msg.content = content
                        try IMCoreManager.shared.database.messageDao.updateMessages(msg)
                        SwiftEventBus.post(IMEvent.MsgUpdate.rawValue, sender: msg)
                    } catch {
                        DDLogError(error)
                    }
                    break
                default:
                    break
                }
            },
            {
                return false
            }
        )
        self.taskId = fileModule.download(url: imageBody.shrinkUrl!, path: path, loadListener: downloadListener)
        self.downloadListener = downloadListener
    }
    
    
    override func disappear() {
        super.disappear()
        self.unregister()
    }
    
    private func unregister() {
        guard let fileModule = IMCoreManager.shared.fileLoadModule else {
            return
        }
        guard let downloadListener = self.downloadListener else {
            return
        }
        guard let taskId = self.taskId else {
            return
        }
        fileModule.cancelUploadListener(taskId: taskId, listener: downloadListener)
        self.taskId = nil
        self.downloadListener = nil
    }
    
}
