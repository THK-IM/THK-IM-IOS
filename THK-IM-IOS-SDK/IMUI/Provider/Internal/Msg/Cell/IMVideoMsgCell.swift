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
import SwiftEventBus

class IMVideoMsgCell: BaseMsgCell {
    
    private var taskId: String?
    private var downloadListener: FileLoaderListener?
    
    private lazy var view : UIImageView = {
        let view = UIImageView()
        durationLabel.font = UIFont.systemFont(ofSize: 10)
        durationLabel.textColor = UIColor.white
        durationLabel.layer.backgroundColor = UIColor.init(hex: "333333").withAlphaComponent(0.5).cgColor
        durationLabel.layer.cornerRadius = 4
        view.addSubview(durationLabel)
        
        playView.image = UIImage(named: "chat_video_play")
        view.addSubview(playView)
        return view
    }()
    private let durationLabel = IMMsgLabelView()
    private let playView = UIImageView()
    
    override func msgView() -> UIView {
        return self.view
    }
    
    override func setMessage(_ msgs: Array<Message>, _ position: Int) {
        super.setMessage(msgs, position)
        guard let msg = self.message else {
            return
        }
        do {
            let videoMsgBody = try JSONDecoder().decode(
                VideoMsgBody.self,
                from: msg.content.data(using: .utf8) ?? Data())
            DDLogDebug("IMVideoMsgCell, id: \(videoMsgBody.url ?? "null")")
            DDLogDebug("IMVideoMsgCell, id: \(videoMsgBody.thumbnailPath ?? "null")")
            if (videoMsgBody.width > videoMsgBody.height) {
                var calWidth = min(160, videoMsgBody.width)
                calWidth = max(100, calWidth)
                let calHeight = max(100, calWidth * videoMsgBody.height / videoMsgBody.width)
                self.view.removeConstraints(self.view.constraints)
                self.view.snp.makeConstraints { make in
                    make.width.equalTo(calWidth)
                    make.height.equalTo(calHeight)
                }
            } else if (videoMsgBody.height > videoMsgBody.width) {
                var calHeight = min(160, videoMsgBody.height)
                calHeight = max(100, calHeight)
                let calWidth = max(100, calHeight * videoMsgBody.width / videoMsgBody.height)
                self.view.removeConstraints(self.view.constraints)
                self.view.snp.makeConstraints { make in
                    make.width.equalTo(calWidth)
                    make.height.equalTo(calHeight)
                }
            }
            self.durationLabel.snp.makeConstraints { make in
                make.bottom.equalToSuperview().offset(-5)
                make.right.equalToSuperview().offset(-5)
                make.height.equalTo(20)
            }
            self.durationLabel.padding = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
            self.playView.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.size.equalTo(40)
            }
            
            if (videoMsgBody.thumbnailPath != nil) {
                // 每次debug运行时 document目录位置会改变，适配一下
                let path = IMCoreManager.shared.storageModule?.sandboxFilePath(videoMsgBody.thumbnailPath!)
                self.view.ca_setImagePathWithCorner(path: path!, radius: 8.0)
                self.playView.isHidden = false
                self.durationLabel.isHidden = false
                self.durationLabel.text = Date().secondToTime(videoMsgBody.duration)
                return
            }
            self.view.image = nil
            self.playView.isHidden = true
            self.durationLabel.isHidden = true
            if (videoMsgBody.thumbnailUrl != nil) {
                self.downloadThumbnailImage(videoMsgBody, msg)
            }
        } catch {
            DDLogError("IMVideoMsgCell error: \(error)")
        }
    }
    
    func downloadThumbnailImage(_ videoMsgBody: VideoMsgBody, _ msg: Message) {
        guard let storageModule = IMCoreManager.shared.storageModule else {
            return
        }
        guard let fileModule = IMCoreManager.shared.fileLoadModule else {
            return
        }
        let (_, name) = storageModule.getPathsFromFullPath(videoMsgBody.thumbnailUrl!)
        let path = storageModule.allocLocalFilePath(msg.sessionId, msg.fromUId, name, "img")
        
        self.unregister()
        let downloadListener = FileLoaderListener(
            {
                [weak self] progress, state, url, path in
                switch state {
                case FileLoaderState.Success.rawValue:
                    do {
                        videoMsgBody.thumbnailPath = path
                        let d = try JSONEncoder().encode(videoMsgBody)
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
        self.taskId = fileModule.download(url: videoMsgBody.thumbnailUrl!, path: path, loadListener: downloadListener)
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

