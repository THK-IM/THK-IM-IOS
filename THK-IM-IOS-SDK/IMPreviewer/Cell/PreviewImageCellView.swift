//
//  MediaPreviewCellView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/26.
//

import UIKit
import CocoaLumberjack

class PreviewImageCellView : PreviewCellView {
    var cellIndex: Int = 0
    private var taskId: String?
    private var listener: FileLoadListener?
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
    
    func showImage() {
        guard let message = self.message else {
            return
        }
        if (message.data != nil) {
            do {
                let data = try JSONDecoder().decode(
                    IMImageMsgData.self,
                    from: message.data!.data(using: .utf8) ?? Data())
                if (data.path != nil) {
                    setImagePath(data.path!)
                } else if (data.thumbnailPath != nil) {
                    setImagePath(data.thumbnailPath!)
                    startDownload(message)
                }
            } catch {
                DDLogError(error)
            }
            return
        }
    }
    
    private func startDownload(_ message: Message) {
        _ = IMCoreManager.shared.getMessageModule().getMsgProcessor(message.type)
                .downloadMsgContent(message, resourceType: IMMsgResourceType.Source.rawValue)
    }
    
    func setImagePath(_ path: String) {
        let realPath = IMCoreManager.shared.storageModule.sandboxFilePath(path)
        self.imageView.setImagePath(realPath)
    }
    
    override func startPreview() {
        showImage()
    }
    
    
    override func stopPreview() {
        self.imageView.zoomScale = 1.0
    }
}
