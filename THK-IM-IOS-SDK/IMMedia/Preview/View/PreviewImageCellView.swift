//
//  MediaPreviewCellView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/26.
//

import UIKit

class PreviewImageCellView : UICollectionViewCell {
    weak var onMediaDownloaded: MediaDownloadDelegate?
    var cellIndex: Int = 0
    var media: Media? = nil
    private var taskId: String?
    private var listener: FileLoaderListener?
    private lazy var progressView: CircleProgressView = {
        let p = CircleProgressView(
            frame: CGRect(x: 0, y: 0, width: 40, height: 40)
        )
        return p
    }()
    
    lazy var imageView: IMZoomImageView = {
        let view = IMZoomImageView(frame: self.contentView.frame)
        view.zoomScale = 1.0
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView() {
        self.contentView.addSubview(imageView)
        self.progressView.center = self.contentView.center
        self.progressView.isHidden = true
        self.contentView.addSubview(progressView)
    }
    
    func setPreviewMedia(_ media: Media) {
        self.media = media
        self.showImage()
    }
    
    func endDisplaying() {
        
    }
    
    func showImage() {
        guard let media = self.media else {
            return
        }
        if media.sourcePath != nil {
            let realPath = IMCoreManager.shared.storageModule.sandboxFilePath(media.sourcePath!)
            if FileManager.default.fileExists(atPath: realPath) {
                setImagePath(realPath)
                return
            }
        } else if media.thumbPath != nil {
            let realPath = IMCoreManager.shared.storageModule.sandboxFilePath(media.thumbPath!)
            setImagePath(realPath)
        }
        
        // 下载原图
        if media.sourceUrl != nil {
            let realPath = IMCoreManager.shared.storageModule.sandboxFilePath(media.sourcePath!)
            self.downloadMedia(media.sourceUrl!, path: realPath)
        }
    }
    
    func downloadMedia(_ url: String, path: String) {
        let fileLoadModule = IMCoreManager.shared.fileLoadModule
        if self.taskId != nil && self.listener != nil {
            fileLoadModule.cancelDownloadListener(taskId: self.taskId!, listener: self.listener!)
        }
        let listener = FileLoaderListener({ [weak self] progress, state, url, path in
            guard let sf = self else {
                return
            }
            switch(state) {
            case FileLoaderState.Init.rawValue:
                break
            case FileLoaderState.Failed.rawValue:
                sf.progressView.isHidden = true
                break
            case FileLoaderState.Success.rawValue:
                sf.progressView.isHidden = true
                sf.updateImagePath(path)
                break
            case FileLoaderState.Ing.rawValue:
                sf.progressView.isHidden = false
                sf.progressView.setProgress(to: progress)
                break
            default:
                break
            }
        }, {
            return true
        })
        let taskId = fileLoadModule.download(key: url, path: path, loadListener: listener)
        self.taskId = taskId
        self.listener = listener
    }
    
    func setImagePath(_ path: String) {
        self.imageView.setImagePath(path)
    }
    
    func updateImagePath(_ path: String) {
        self.imageView.setImagePath(path)
        guard let media = self.media else {
            return
        }
        self.onMediaDownloaded?.onMediaDownload(media.id, 2, path)
    }
}
