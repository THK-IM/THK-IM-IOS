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
import SJMediaCacheServer
import SJBaseVideoPlayer

public class PreviewVideoCellView : PreviewCellView {
    
    var cellIndex: Int = 0
    private var taskId: String?
    private var listener: FileLoadListener?
    
    lazy var imageView: UIImageView = {
        let view = UIImageView(frame: self.contentView.frame)
        view.isUserInteractionEnabled = true
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(self.imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func setMessage(_ message: Message) {
        super.setMessage(message)
        self.showImage()
    }
    
    public func showImage() {
        guard let message = self.message else {
            return
        }
        do {
            if (message.data != nil) {
                let data = try JSONDecoder().decode(
                    IMVideoMsgData.self,
                    from: message.data!.data(using: .utf8) ?? Data())
                if (data.thumbnailPath != nil) {
                    let realPath = IMCoreManager.shared.storageModule.sandboxFilePath(data.thumbnailPath!)
                    self.imageView.renderImageByPath(path: realPath)
                }
            }
        } catch {
            DDLogError("\(error)")
        }
    }
    
    private func getRealUrl(url: String, message: Message) -> String {
        if (url.hasPrefix("http")) {
            return url
        } else {
            return "\(IMCoreManager.shared.api.getEndpoint())/session/object/download_url?id=\(url)"
        }
    }
    
    
    private func updateMessage(_ cacheFileUrl: URL) {
        DispatchQueue.global().async { [weak self] in 
            guard let message = self?.message else {
                return
            }
            do {
                guard let file = try FileManager.default.contentsOfDirectory(
                    atPath: cacheFileUrl.path
                ).first else { return }
                let sourcePath = "\(cacheFileUrl.path)/\(file)"
                if (message.content != nil) {
                    let body = try JSONDecoder().decode(
                        IMVideoMsgBody.self,
                        from: message.content!.data(using: .utf8) ?? Data()
                    )
                    if (body.url == nil) {
                        return
                    }
                    var data: IMVideoMsgData? = nil
                    if (message.data != nil) {
                        data = try JSONDecoder().decode(
                            IMVideoMsgData.self,
                            from: message.data!.data(using: .utf8) ?? Data()
                        )
                        if (data!.path != nil) {
                            return
                        }
                    } else {
                        data = IMVideoMsgData()
                    }
                    let path = IMCoreManager.shared.storageModule.allocSessionFilePath(
                            message.sessionId,
                            body.name ?? String().random(8),
                            IMFileFormat.Video.rawValue
                        )
                    try IMCoreManager.shared.storageModule.copyFile(sourcePath, path)
                    if (data != nil) {
                        data!.path = path
                        data!.height = body.width
                        data!.width = body.duration
                        data!.duration = body.duration
                        let d = try JSONEncoder().encode(data)
                        message.data = String(data: d, encoding: .utf8)!
                        try IMCoreManager.shared.messageModule.getMsgProcessor(message.type)
                            .insertOrUpdateDb(message, true, false)
                    }
                }
            } catch {
                DDLogError("\(error)")
            }
        }
    }
    
    public override func startPreview() {
        guard let message = self.message else {
            return
        }
        guard let vc = self.parentController() as? IMMediaPreviewController else { return }
        let player = vc.videoPlayer
        self.imageView.addSubview(player.view)
        player.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        var sourcePath: String? = nil
        var sourceUrl: String? = nil
        do {
            if (message.data != nil) {
                let data = try JSONDecoder().decode(
                    IMVideoMsgData.self,
                    from: message.data!.data(using: .utf8) ?? Data())
                sourcePath = data.path
            }
            if (message.content != nil) {
                let body = try JSONDecoder().decode(
                    IMVideoMsgBody.self,
                    from: message.content!.data(using: .utf8) ?? Data())
                sourceUrl = body.url
            }
        } catch {
            DDLogError("\(error)")
        }
        
        if (sourcePath != nil) {
            let realPath = IMCoreManager.shared.storageModule.sandboxFilePath(sourcePath!)
            let videoUrl = URL(fileURLWithPath: realPath)
            player.urlAsset = SJVideoPlayerURLAsset.init(url: videoUrl)
            player.play()
        } else if (sourceUrl != nil) {
            let realUrlString = self.getRealUrl(url: sourceUrl!, message: message)
            guard let realUrl = URL(string: realUrlString) else { return }
            if MCSAssetManager.shared().isAssetStored(for: realUrl) {
                if let asset = MCSAssetManager.shared().asset(with: realUrl) {
                    let pathUrl = URL(fileURLWithPath: asset.path)
                    self.updateMessage(pathUrl)
                }
            }
            guard let cacheUrl = SJMediaCacheServer.shared().playbackURL(with: realUrl) else { return }
            player.urlAsset = SJVideoPlayerURLAsset.init(url: cacheUrl)
            player.play()
        }
        
    }
    
}
