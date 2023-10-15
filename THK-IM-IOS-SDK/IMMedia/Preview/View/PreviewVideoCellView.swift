//
//  PreviewVideoCellView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/11.
//

import Foundation
import UIKit
import AVFoundation

class PreviewVideoCellView : UICollectionViewCell {
    
    weak var onMediaDownloaded: MediaDownloadDelegate?
    var cellIndex: Int = 0
    var media: Media? = nil
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
    
    func endDisplaying() {
        self.videoPlayView.pause()
    }
    
    func setupView() {
        self.addSubview(self.videoPlayView)
        self.progressView.center = self.contentView.center
        self.progressView.isHidden = true
        self.contentView.addSubview(progressView)
    }
    
    func setPreviewMedia(_ media: Media) {
        self.media = media
        self.showVideo()
    }
    
    func showVideo() {
        guard let media = self.media else {
            return
        }
        if media.duration != nil {
            self.videoPlayView.initDuration(media.duration!)
        }
        if media.thumbPath != nil {
            self.videoPlayView.initCover(media.thumbPath!)
        }
        if media.sourcePath != nil {
            let realPath = IMCoreManager.shared.storageModule.sandboxFilePath(media.sourcePath!)
            if FileManager.default.fileExists(atPath: realPath) {
                self.videoPlayView.initDataSource(NSURL(fileURLWithPath: realPath) as URL)
                self.videoPlayView.play()
                return
            }
        }
        
        if media.sourceUrl != nil {
            guard let url = NSURL(string: media.sourceUrl!) as URL? else {
                return
            }
            self.videoPlayView.initDataSource(url)
            self.videoPlayView.play()
        }
    }
    
}
