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
        
        var sourceUrl: String? = nil
        do {
            if (message.content != nil) {
                let body = try JSONDecoder().decode(
                    IMVideoMsgBody.self,
                    from: message.content!.data(using: .utf8) ?? Data())
                sourceUrl = body.url
            }
        } catch {
            DDLogError("\(error)")
        }
        
       if (sourceUrl != nil) {
            let realUrlString = self.getRealUrl(url: sourceUrl!, message: message)
            guard let realUrl = URL(string: realUrlString) else { return }
            guard let cacheUrl = SJMediaCacheServer.shared().playbackURL(with: realUrl) else { return }
            player.urlAsset = SJVideoPlayerURLAsset.init(url: cacheUrl)
            player.play()
        }
        
    }
    
}
