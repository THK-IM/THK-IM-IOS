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
    private var listener: LoadListener?
    
    
    private lazy var progressView: CircleProgressView = {
        let p = CircleProgressView(
            frame: CGRect(x: 0, y: 0, width: 40, height: 40)
        )
        return p
    }()
    
    private lazy var videoPlayView: IMVideoPlayerView = {
        let v = IMVideoPlayerView(frame: self.contentView.frame)
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
            let realPath = IMManager.shared.storageModule!.sandboxFilePath(media.sourcePath!)
            if FileManager.default.fileExists(atPath: realPath) {
                self.play(path: realPath)
                return
            }
        }
        
        if media.sourceUrl != nil && media.sourcePath != nil {
            let realPath = IMManager.shared.storageModule!.sandboxFilePath(media.sourcePath!)
            self.downloadMedia(media.sourceUrl!, path: realPath)
        }
    }
    
    func play(path: String) {
        self.videoPlayView.initDataSource(NSURL(fileURLWithPath: path) as URL)
//        self.videoPlayView.play()
    }
    
    func updatePlayer(path: String) {
        self.play(path: path)
        guard let media = self.media else {
            return
        }
        self.onMediaDownloaded?.onMediaDownload(media.id, 2, path)
    }
    
    func downloadMedia(_ url: String, path: String) {
        guard let fileLoader = IMManager.shared.fileLoadModule else {
            return
        }
        if self.taskId != nil && self.listener != nil {
            fileLoader.cancelDownloadListener(taskId: self.taskId!, listener: self.listener!)
        }
        let listener = LoadListener({ [weak self] progress, state, url, path in
            guard let sf = self else {
                return
            }
            switch(state) {
            case LoadState.Init.rawValue:
                break
            case LoadState.Failed.rawValue:
                sf.progressView.isHidden = true
                break
            case LoadState.Success.rawValue:
                sf.progressView.isHidden = true
                sf.updatePlayer(path: path)
                break
            case LoadState.Ing.rawValue:
                sf.progressView.isHidden = false
                sf.progressView.setProgress(to: progress)
                break
            default:
                break
            }
        }, {
            return true
        })
        let taskId = fileLoader.download(url: url, path: path, loadListener: listener)
        self.taskId = taskId
        self.listener = listener
    }
    
}
