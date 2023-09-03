//
//  IMMessageViewController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/28.
//

import Foundation
import RxSwift
import UIKit
import CocoaLumberjack
import SnapKit
import ZLPhotoBrowser
import Photos
import SwiftEventBus
import RxGesture

class IMMessageViewController : UIViewController, IMMsgSender, IMMsgPreviewer, MediaDownloadDelegate {
    
    var session: Session? = nil
    private var containerView = UIView()
//    private var alwaysShowView = UIView()
    private var messageLayout = IMMessageLayout()
    private var inputLayout = IMInputLayout()
    private var bottomPanelLayout = IMBottomPanelLayout()
    private var msgCheckedLayout = IMMsgCheckedLayout()
    private var keyboardShow = false
    
    deinit {
        DDLogDebug("IMMessageViewController, de init")
        unregisterMsgEvent()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.init(hex: "e2e2e2")
        self.setupView()
        self.registerMsgEvent()
        self.registerKeyboardEvent()
        self.messageLayout.loadMessages()
    }
    
    private func setupView() {
        self.view.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(UIApplication.shared.windows[0].safeAreaInsets.top+getNavHeight())
            make.bottom.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        containerView.clipsToBounds = true
        
        self.containerView.addSubview(self.bottomPanelLayout)
        self.bottomPanelLayout.sender = self
        self.bottomPanelLayout.snp.makeConstraints { [weak self] make in
            guard let sf = self else {
                return
            }
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview().offset(-UIApplication.shared.windows[0].safeAreaInsets.bottom)
            make.height.equalTo(sf.bottomPanelLayout.getLayoutHeight()) // 高度内部自己计算
        }
        
        // 输入框等布局
        self.inputLayout.sender = self
        self.inputLayout.backgroundColor = UIColor.init(hex: "eaeaea")
        self.containerView.addSubview(self.inputLayout)
        self.inputLayout.snp.makeConstraints { [weak self] make in
            guard let sf = self else {
                return
            }
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalTo(sf.bottomPanelLayout.snp.top)
            make.height.equalTo(sf.inputLayout.getLayoutHeight()) // 高度内部自己计算
        }
        
        // 多选msg视图
        self.containerView.addSubview(self.msgCheckedLayout)
        self.msgCheckedLayout.sender = self
        self.msgCheckedLayout.alpha = 1
        self.msgCheckedLayout.backgroundColor = UIColor.init(hex: "e2e2e2")
        self.msgCheckedLayout.isHidden = true
        self.msgCheckedLayout.snp.makeConstraints { [weak self] make in
            guard let sf = self else {
                return
            }
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalTo(sf.bottomPanelLayout.snp.top)
            make.height.equalTo(sf.msgCheckedLayout.getLayoutHeight()) // 高度内部自己计算
        }
        
        // 消息视图，在输入框之上，铺满alwaysShowView
        self.containerView.addSubview(self.messageLayout)
        self.messageLayout.backgroundColor = UIColor.init(hex: "e2e2e2")
        self.messageLayout.session = self.session
        self.messageLayout.sender = self
        self.messageLayout.previewer = self
        self.messageLayout.snp.makeConstraints { [weak self] make in
            guard let sf = self else {
                return
            }
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalTo(sf.inputLayout.snp.top)
        }
    }
    
    private func getSafeBottomHeight() -> CGFloat {
        guard let window = UIApplication.shared.windows.first else {
            return 0
        }
        return window.safeAreaInsets.bottom
    }
    
    private func getNavHeight() -> CGFloat {
        var navHeight: CGFloat = 0
        if (self.navigationController != nil) {
            navHeight = self.navigationController!.navigationBar.frame.size.height
        }
        return navHeight
    }
    
    func registerKeyboardEvent() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillAppear), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillDisappear), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillAppear(note: NSNotification) {
        let keyboard = note.userInfo![UIResponder.keyboardFrameEndUserInfoKey]
        let keyboardHeight : CGFloat = (keyboard as AnyObject).cgRectValue.size.height
        let animation = note.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey]
        let duration: Double = (animation as AnyObject).doubleValue
        
        self.keyboardShow = true
        let height = keyboardHeight
        self.moveUpAlwaysShowView(true, height, duration)
    }
    
    @objc func keyboardWillDisappear(note: NSNotification){
        let animation = note.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey]
        let duration: Double = (animation as AnyObject).doubleValue
        let height = self.bottomPanelLayout.getLayoutHeight()
        self.moveUpAlwaysShowView(false, height, duration)
    }
    
    func registerMsgEvent() {
        SwiftEventBus.onMainThread(self, name: IMEvent.BatchMsgNew.rawValue, handler: { [weak self ] result in
            guard let tuple = result?.object as? (Int64, Array<Message>) else {
                return
            }
            if tuple.0 != self?.session?.id {
                return
            }
            self?.messageLayout.insertMessages(tuple.1)
        })
        
        SwiftEventBus.onMainThread(self, name: IMEvent.MsgNew.rawValue, handler: { [weak self ] result in
            guard let msg = result?.object as? Message else {
                return
            }
            if msg.sessionId != self?.session?.id {
                return
            }
            DDLogDebug("IMEvent: \(IMEvent.MsgNew.rawValue)")
            self?.messageLayout.insertMessage(msg)
        })
        SwiftEventBus.onMainThread(self, name: IMEvent.MsgUpdate.rawValue, handler: { [weak self ]result in
            guard let msg = result?.object as? Message else {
                return
            }
            if msg.sessionId != self?.session?.id {
                return
            }
            DDLogDebug("IMEvent: \(IMEvent.MsgUpdate.rawValue)")
            self?.messageLayout.insertMessage(msg)
        })
        
        SwiftEventBus.onMainThread(self, name: IMEvent.MsgDelete.rawValue, handler: { [weak self ]result in
            guard let msg = result?.object as? Message else {
                return
            }
            if msg.sessionId != self?.session?.id {
                return
            }
            DDLogDebug("IMEvent: \(IMEvent.MsgUpdate.rawValue)")
            self?.messageLayout.deleteMessage(msg)
        })
    }
    
    func unregisterMsgEvent() {
        SwiftEventBus.unregister(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        _ = inputLayout.endEditing(true)
    }
    
    func showBottomPanel(_ type: Int) {
        self.bottomPanelLayout.showBottomPanel(type)
    }
    
    func closeBottomPanel() {
        self.bottomPanelLayout.closeBottomPanel()
    }
    
    func sendInputContent() {
        return self.inputLayout.sendInputContent()
    }
    
    func addInputContent(text: String) {
        self.inputLayout.addInputText(text)
    }
    
    func deleteInputContent(count: Int) {
        self.inputLayout.deleteInputContent(count)
    }
    
    func openKeyboard() -> Bool {
        self.inputLayout.openKeyboard()
    }
    
    func isKeyboardShowing() -> Bool {
        return self.keyboardShow
    }
    
    func closeKeyboard() -> Bool {
        self.inputLayout.closeKeyboard()
    }
    
    func moveUpAlwaysShowView(_ isKeyboardShow: Bool, _ height: CGFloat, _ duration: Double) {
        self.inputLayout.onKeyboardChange(isKeyboardShow, duration, height)
        if (height > 0) {
            self.bottomPanelLayout.onKeyboardChange(isKeyboardShow, duration, height)
        }
        
        self.bottomPanelLayout.snp.updateConstraints { make in
            let offset = height == 0 ? -UIApplication.shared.windows[0].safeAreaInsets.bottom : 0
            make.height.equalTo(height)
            make.bottom.equalToSuperview().offset(offset)
        }
        
        UIView.animate(withDuration: duration, animations: { [weak self] in
            guard let sf = self else {
                return
            }
            if height > 0 {
                sf.messageLayout.layoutResize(height-UIApplication.shared.windows[0].safeAreaInsets.bottom)
            } else {
                sf.messageLayout.layoutResize(height)
            }
            sf.containerView.layoutIfNeeded()
        }, completion: { [weak self] (finished) in
            if !finished {
                return
            }
            guard let sf = self else {
                return
            }
            if height <= 0 {
                sf.bottomPanelLayout.onKeyboardChange(isKeyboardShow, duration, height)
            }
        })
    }
    
    
    func moveToLatestMessage() {
        self.messageLayout.scrollToBottom()
    }
    
    func resendMessage(_ msg: Message) {
        IMCoreManager.shared.getMessageModule().getMsgProcessor(msg.type).resend(msg)
    }
    
    func getSession() -> Session? {
        return self.session
    }
    
    
    func sendMessage(_ type: Int, _ body: String) {
        guard let sessionId = self.session?.id else {
            return
        }
        let success = IMCoreManager.shared.getMessageModule().getMsgProcessor(type).sendMessage(body, sessionId)
        DDLogInfo("sendMessage \(success)")
    }
    
    /// 显示消息多选视图
    func showMsgSelectedLayout() {
        self.messageLayout.setMessageEditing(true)
        self.msgCheckedLayout.isHidden = false
//        self.inputLayout.isHidden = true
    }
    
    /// 关闭消息多选视图
    func dismissMsgSelectedLayout() {
        self.messageLayout.setMessageEditing(false)
        self.msgCheckedLayout.isHidden = true
//        self.inputLayout.isHidden = false
    }
    
    
    func choosePhoto() {
        let ps = ZLPhotoPreviewSheet()
        ps.selectImageBlock = { [weak self] results, isOriginal in
            guard let sf = self else {
                return
            }
            do {
                for r in results {
                    try sf.onMediaResult(r, isOriginal)
                }
            } catch {
                DDLogError(error)
            }
        }
        ps.showPhotoLibrary(sender: self)
    }
    
    func openCamera() {
        ZLPhotoConfiguration.default()
            .cameraConfiguration
            .maxRecordDuration(300)
            .allowRecordVideo(true)
            .allowSwitchCamera(true)
            .showFlashSwitch(true)

        let camera = ZLCustomCamera()
        camera.takeDoneBlock = { [weak self] image, videoUrl in
            guard let sf = self else {
                return
            }
            if image != nil {
                do {
                    try sf.sendImage(image!)
                } catch {
                    DDLogError(error)
                }
            } else if (videoUrl != nil) {
                do {
                    let asset = AVURLAsset(url: videoUrl!)
                    let videoData = try Data(contentsOf: asset.url)
                    let storageModule = IMCoreManager.shared.storageModule
                    let (_, fName) = storageModule.getPathsFromFullPath(asset.url.absoluteString)
                    let (name, ext) = storageModule.getFileExt(fName)
                    let fileName = "\(name)_\(String().random(8)).\(ext)"
                    let path = storageModule.allocSessionFilePath(
                        (sf.session?.id)!, IMCoreManager.shared.uId, fileName, "video")
                    try storageModule.saveMediaDataInto(path, videoData)
                    try sf.sendVideo(path)
                } catch {
                    DDLogError(error)
                }
            } else {
                // TODO
            }
        }
        self.showDetailViewController(camera, sender: nil)
    }
    
    
    func onMediaResult(_ r: ZLResultModel, _ isOriginal: Bool) throws {
        switch r.asset.mediaType {
        case PHAssetMediaType.image:
            try self.sendImage(r.image)
            break
        case PHAssetMediaType.video:
            PHCachingImageManager.default()
                .requestAVAsset(forVideo: r.asset, options: nil)
            { [weak self] asset, audioMix, info in
                guard let urlAsset = asset as? AVURLAsset else {
                    return
                }
                do {
                    let videoData = try Data(contentsOf: urlAsset.url)
                    let storageModule = IMCoreManager.shared.storageModule
                    let (_, fName) = storageModule.getPathsFromFullPath(urlAsset.url.absoluteString)
                    let (name, ext) = storageModule.getFileExt(fName)
                    let fileName = "\(name)_\(String().random(8)).\(ext)"
                    let path = storageModule.allocSessionFilePath(
                        (self?.session?.id)!, IMCoreManager.shared.uId, fileName, "video")
                    try storageModule.saveMediaDataInto(path, videoData)
                    try self?.sendVideo(path, r.image, Int(r.asset.duration))
                } catch {
                    DDLogError(error)
                }
            }
            break
        default:
            break
        }
    }
    
    private func sendVideo(_ path: String, _ image: UIImage? = nil, _ duration: Int? = nil) throws {
//        let videoBody = IMVideoMsgBody()
//        videoBody.path = path
//        if image != nil {
//            videoBody.width = Int(image!.size.width)
//            videoBody.height = Int(image!.size.height)
//        } else {
//            videoBody.width = 100
//            videoBody.height = 160
//        }
//        if duration != nil {
//            videoBody.duration = duration!
//        }
//        let d = try JSONEncoder().encode(videoBody)
//        self.sendMessage(MsgType.VIDEO.rawValue, String(data: d, encoding: .utf8)!)
    }
    
    private func sendImage(_ image: UIImage) throws {
//        guard let storageModule = IMCoreManager.shared.storageModule else {
//            return
//        }
//        var data = image.pngData()
//        if (data == nil) {
//            data = image.jpegData(compressionQuality: 1)
//        }
//        if (data != nil) {
//            let ext = data!.detectImageType().rawValue
//            let fileName = "\(String().random(8)).\(ext)"
//            let localPath = storageModule.allocSessionFilePath((self.session?.id)!, IMCoreManager.shared.uId, fileName, "img")
//            try IMCoreManager.shared.storageModule?.saveMediaDataInto(localPath, data!)
//
//            let imageBody = ImageMsgBody()
//            imageBody.width = Int(image.size.width)
//            imageBody.height = Int(image.size.height)
//            imageBody.path = localPath
//            let d = try JSONEncoder().encode(imageBody)
//            self.sendMessage(MsgType.IMAGE.rawValue, String(data: d, encoding: .utf8)!)
//        }
    }
    
    private func msgToMedia(msg: Message) -> Media? {
//        do {
//            if msg.type == MsgType.IMAGE.rawValue {
//                let imageBody = try JSONDecoder().decode(
//                    ImageMsgBody.self,
//                    from: msg.content.data(using: .utf8) ?? Data()
//                )
//                if imageBody.path == nil && imageBody.url != nil {
//                    let (_, fileName) = IMCoreManager.shared.storageModule!.getPathsFromFullPath(imageBody.url!)
//                    imageBody.path = IMCoreManager.shared.storageModule?
//                        .allocLocalFilePath(msg.sessionId, msg.fromUId, fileName, "img")
//                }
//                return Media.imageMedia(
//                    id: "\(msg.msgId)",
//                    width: imageBody.width,
//                    height: imageBody.height,
//                    sourcePath: imageBody.path,
//                    sourceUrl: imageBody.url,
//                    thumbPath: imageBody.shrinkPath,
//                    thumbUrl: imageBody.shrinkUrl
//                )
//            } else if msg.type == MsgType.VIDEO.rawValue {
//                let videoBody = try JSONDecoder().decode(
//                    VideoMsgBody.self,
//                    from: msg.content.data(using: .utf8) ?? Data()
//                )
//                if videoBody.path == nil && videoBody.url != nil {
//                    let (_, fileName) = IMCoreManager.shared.storageModule!.getPathsFromFullPath(videoBody.url!)
//                    videoBody.path = IMCoreManager.shared.storageModule?
//                        .allocSessionFilePath(msg.sessionId, msg.fromUId, fileName, "video")
//                }
//                return Media.videoMedia(
//                    id: "\(msg.msgId)",
//                    duration: videoBody.duration,
//                    width: videoBody.width,
//                    height: videoBody.height,
//                    sourcePath: videoBody.path,
//                    sourceUrl: videoBody.url,
//                    thumbPath: videoBody.thumbnailPath,
//                    thumbUrl: videoBody.thumbnailUrl
//                )
//            }
//        } catch {
//            DDLogError(error)
//        }
        return nil
    }
    
    func previewMessage(_ msg: Message, _ position: Int,  _ originView: UIView) {
        if msg.type != MsgType.IMAGE.rawValue && msg.type != MsgType.VIDEO.rawValue {
            return
        }
        var ay = [Media]()
        ay.append(contentsOf: self.fetchMoreMessage(msg.msgId, msg.sessionId, true, 5).reversed())
        let current = self.msgToMedia(msg: msg)
        if current != nil {
            ay.append(current!)
        }
        ay.append(contentsOf: self.fetchMoreMessage(msg.msgId, msg.sessionId, false, 5))
        let absoluteFrame = originView.convert(originView.bounds, to: nil)
        MediaPreviewController.preview(
            from: self, onMediaDownloaded: self,
            source: ay, defaultId: String(msg.msgId),
            enterFrame: absoluteFrame
        )
    }
    
    func onMediaDownload(_ id: String, _ resourceType: Int, _ path: String) {
        DispatchQueue.global().async { [weak self] in
            self?.updateMediaMessage(id, resourceType, path)
        }
    }
    
    func onMoreMediaFetch(_ id: String, _ before: Bool, _ count: Int) -> [Media] {
        guard let msgId: Int64 = Int64(id) else {
            return []
        }
        guard let sessionId = self.session?.id else {
            return []
        }
        return self.fetchMoreMessage(msgId, sessionId, before, count)
    }
    
    private func fetchMoreMessage(_ msgId: Int64, _ sessionId: Int64, _ before: Bool, _ count: Int) -> [Media] {
//        do {
//            let types = [MsgType.IMAGE.rawValue, MsgType.VIDEO.rawValue]
//            let msgDao = IMCoreManager.shared.database.messageDao
//            var messages: [Message]? = nil
//            if before {
//                messages = try msgDao.findOlderMessages(msgId, types, sessionId, count)
//            } else {
//                messages = try msgDao.findNewerMessages(msgId, types, sessionId, count)
//            }
//            var medias = [Media]()
//            if messages != nil {
//                for msg in messages! {
//                    guard let m = self.msgToMedia(msg: msg) else {
//                        continue
//                    }
//                    medias.append(m)
//                }
//            }
//            return medias
//        } catch {
//            DDLogError(error)
//        }
        return []
    }
    
    private func updateMediaMessage(_ id: String, _ resourceType: Int, _ path: String) {
//        guard let msgId: Int64 = Int64(id) else {
//            return
//        }
//        guard let sessionId: Int64 = self.session?.id else {
//            return
//        }
//        do {
//            guard let msg = try IMCoreManager.shared.database.messageDao.findMessageBySid(msgId, sessionId) else {
//                return
//            }
//            if msg.type == MsgType.IMAGE.rawValue {
//                let imageBody = try JSONDecoder().decode(
//                    ImageMsgBody.self,
//                    from: msg.content.data(using: .utf8) ?? Data()
//                )
//                if resourceType == 1 {
//                    // 缩略图
//                    imageBody.shrinkPath = path
//                } else {
//                    imageBody.path = path
//                }
//                let data = try JSONEncoder().encode(imageBody)
//                let content = String(data: data, encoding: .utf8)
//                if content != nil {
//                    msg.content = content!
//                    try IMCoreManager.shared.database.messageDao.updateMessages(msg)
//                    SwiftEventBus.post(IMEvent.MsgUpdate.rawValue, sender: msg)
//                }
//
//            } else if msg.type == MsgType.VIDEO.rawValue {
//                let videoMsgBody = try JSONDecoder().decode(
//                    VideoMsgBody.self,
//                    from: msg.content.data(using: .utf8) ?? Data()
//                )
//                if resourceType == 1 {
//                    // 缩略图
//                    videoMsgBody.thumbnailPath = path
//                } else {
//                    videoMsgBody.path = path
//                }
//                let data = try JSONEncoder().encode(videoMsgBody)
//                let content = String(data: data, encoding: .utf8)
//                if content != nil {
//                    msg.content = content!
//                    try IMCoreManager.shared.database.messageDao.updateMessages(msg)
////                    SwiftEventBus.post(IMEvent.MsgUpdate.rawValue, sender: msg)
//                }
//            }
//        } catch {
//            DDLogError(error)
//        }
    }
    
}

