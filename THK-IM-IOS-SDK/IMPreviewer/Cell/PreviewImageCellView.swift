//
//  MediaPreviewCellView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/26.
//

import CocoaLumberjack
import UIKit

public class PreviewImageCellView: PreviewCellView {
    var cellIndex: Int = 0
    private var taskId: String?
    private var listener: FileLoadListener?

    private lazy var progressView: CircularProgressBarView = {
        let p = CircularProgressBarView(
            frame: CGRect(x: 0, y: 0, width: 40, height: 40)
        )
        return p
    }()

    lazy var imageView: IMZoomImageView = {
        let view = IMZoomImageView(frame: self.contentView.frame)
        view.zoomScale = 1.0
        return view
    }()

    deinit {
        print("deinit PreviewImageCellView")
    }

    override init(frame: CGRect) {
        print("deinit init PreviewImageCellView")
        super.init(frame: frame)
        self.setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setupView() {
        self.contentView.addSubview(imageView)
        self.progressView.center = self.contentView.center
        self.progressView.isHidden = true
        self.contentView.addSubview(progressView)
    }

    override public func setMessage(_ message: Message) {
        super.setMessage(message)
        self.imageView.clearImage()
        self.imageView.previewDelegate = delegate
        self.showImage()
    }

    public func showImage() {
        guard let message = self.message else {
            return
        }
        if message.data != nil {
            do {
                let data = try JSONDecoder().decode(
                    IMImageMsgData.self,
                    from: message.data!.data(using: .utf8) ?? Data())
                if data.path != nil {
                    self.setImagePath(data.path!)
                } else {
                    if data.thumbnailPath != nil {
                        self.setImagePath(data.thumbnailPath!)
                    }
                    self.startDownload(message)
                }
            } catch {
                DDLogError("\(error)")
            }
            return
        } else {
            self.startDownload(message)
        }
    }

    open override func onIMLoadProgress(_ loadProgress: IMLoadProgress) {
        guard let message = self.message else {
            return
        }
        if message.content != nil {
            do {
                let content = try JSONDecoder().decode(
                    IMImageMsgBody.self,
                    from: message.content!.data(using: .utf8) ?? Data())
                if content.url != loadProgress.url {
                    self.progressView.isHidden = true
                    return
                }
            } catch {
                DDLogError("\(error)")
                return
            }
        }
        if loadProgress.state == FileLoadState.Success.rawValue {
            self.progressView.isHidden = true
            if message.data != nil {
                do {
                    let data = try JSONDecoder().decode(
                        IMImageMsgData.self,
                        from: message.data!.data(using: .utf8) ?? Data())
                    data.path = loadProgress.path
                    let newData = try JSONEncoder().encode(data)
                    message.data = String.init(data: newData, encoding: .utf8)
                    self.setImagePath(loadProgress.path)
                } catch {
                    DDLogError("\(error)")
                }
            } else {
                let data = IMImageMsgData()
                data.path = loadProgress.path
                let newData = try? JSONEncoder().encode(data)
                message.data = String.init(data: newData ?? Data(), encoding: .utf8)
                self.setImagePath(loadProgress.path)
            }
        } else if loadProgress.state == FileLoadState.Ing.rawValue
            || loadProgress.state == FileLoadState.Init.rawValue
        {
            self.progressView.isHidden = false
            self.progressView.setProgress(Double(loadProgress.progress))
        } else {
            self.progressView.isHidden = true
        }
    }

    private func startDownload(_ message: Message) {
        _ = IMCoreManager.shared.messageModule.getMsgProcessor(message.type)
            .downloadMsgContent(message, resourceType: IMMsgResourceType.Source.rawValue)
    }

    public func setImagePath(_ path: String) {
        let realPath = IMCoreManager.shared.storageModule.sandboxFilePath(path)
        self.imageView.setImagePath(realPath)
    }

}
