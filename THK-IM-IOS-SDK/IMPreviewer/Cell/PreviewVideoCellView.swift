//
//  PreviewVideoCellView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/11.
//

import Foundation
import UIKit
import AVFoundation
import CocoaLumberjack

class PreviewVideoCellView : PreviewCellView {
    
    var cellIndex: Int = 0
    private var taskId: String?
    private var listener: FileLoadListener?
    
    
    private lazy var progressView: CircleProgressView = {
        let p = CircleProgressView(
            frame: CGRect(x: 0, y: 0, width: 40, height: 40)
        )
        return p
    }()
    
    private lazy var videoPlayView: IMCacheVideoPlayerView = {
        let v = IMCacheVideoPlayerView(frame: self.contentView.frame)
        return v
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView() {
        self.addSubview(self.videoPlayView)
        self.progressView.center = self.contentView.center
        self.progressView.isHidden = true
        self.contentView.addSubview(progressView)
    }
    
    func showVideo() {
        guard let message = self.message else {
            return
        }
        var duration = 0
        var coverPath : String? = nil
        var coverUrl: String? = nil
        var sourcePath: String? = nil
        var sourceUrl: String? = nil
        do {
            if (message.data != nil) {
                let data = try JSONDecoder().decode(
                    IMVideoMsgData.self,
                    from: message.data!.data(using: .utf8) ?? Data())
                if (data.duration != nil) {
                    duration = data.duration!
                }
                sourcePath = data.path
                coverPath = data.thumbnailPath
            }
            if (message.content != nil) {
                let body = try JSONDecoder().decode(
                    IMVideoMsgBody.self,
                    from: message.content!.data(using: .utf8) ?? Data())
                if (body.duration != nil) {
                    duration = body.duration!
                }
                sourceUrl = body.url
                coverUrl = body.thumbnailUrl
            }
        } catch {
            DDLogError(error)
        }
        
        self.videoPlayView.initDuration(duration)
        if (coverPath != nil) {
            let realPath = IMCoreManager.shared.storageModule.sandboxFilePath(coverPath!)
            self.videoPlayView.initCover(realPath)
        } else if (coverUrl != nil) {
            _ = IMCoreManager.shared.getMessageModule().getMsgProcessor(message.type)
                .downloadMsgContent(message, resourceType: IMMsgResourceType.Thumbnail.rawValue)
        }
        if (sourcePath != nil) {
            let realPath = IMCoreManager.shared.storageModule.sandboxFilePath(sourcePath!)
            self.videoPlayView.initDataSource(NSURL(fileURLWithPath: realPath) as URL)
        } else if (sourceUrl != nil) {
            guard let url = NSURL(string: sourceUrl!) as URL? else {
                return
            }
            self.videoPlayView.initDataSource(url)
        }
    }
    
    override func startPreview() {
        self.showVideo()
    }
    
    override func stopPreview() {
        self.videoPlayView.pause()
    }
    
}
