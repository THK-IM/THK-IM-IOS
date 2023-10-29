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
import Photos
import SwiftEventBus
import RxGesture
import ImageIO
import CoreServices

class IMMessageViewController : UIViewController, IMMsgSender, IMMsgPreviewer {
    
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
    
    
    func sendMessage(_ type: Int, _ body: Codable) {
        guard let sessionId = self.session?.id else {
            return
        }
        let success = IMCoreManager.shared.getMessageModule().sendMessage(body, sessionId, type, nil, nil)
        DDLogDebug("sendMessage \(success)")
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
        guard let cp = IMUIManager.shared.contentProvider else {
            return
        }
        cp.pick(controller: self, formats: [IMFileFormat.Image, IMFileFormat.Video]) { [weak self] result, cancel in
            guard let sf = self else {
                return
            }
            do {
                for r in result {
                    if (r.mimeType.starts(with: IMFileFormat.Image.rawValue)) {
                        var ext = r.mimeType.replacingOccurrences(of: IMFileFormat.Image.rawValue, with: "")
                        ext = ext.replacingOccurrences(of: "/", with: "")
                        try sf.sendImage(r.data, ext: ext)
                    } else if (r.mimeType.starts(with: IMFileFormat.Video.rawValue)) {
                        var ext = r.mimeType.replacingOccurrences(of: IMFileFormat.Video.rawValue, with: "")
                        ext = ext.replacingOccurrences(of: "/", with: "")
                        try sf.sendVideo(r.data, ext: ext)
                    }
                }
            } catch {
                DDLogError(error)
            }
        }
    }
    
    func openCamera() {
        guard let cp = IMUIManager.shared.contentProvider else {
            return
        }
        cp.openCamera(controller: self, formats: [IMFileFormat.Image, IMFileFormat.Video]) { [weak self] result, cancel in
            guard let sf = self else {
                return
            }
            do {
                for r in result {
                    if (r.mimeType.starts(with: IMFileFormat.Image.rawValue)) {
                        var ext = r.mimeType.replacingOccurrences(of: IMFileFormat.Image.rawValue, with: "")
                        ext = ext.replacingOccurrences(of: "/", with: "")
                        try sf.sendImage(r.data, ext: ext)
                    } else if (r.mimeType.starts(with: IMFileFormat.Video.rawValue)) {
                        var ext = r.mimeType.replacingOccurrences(of: IMFileFormat.Video.rawValue, with: "")
                        ext = ext.replacingOccurrences(of: "/", with: "")
                        try sf.sendVideo(r.data, ext: ext)
                    }
                }
            } catch {
                DDLogError(error)
            }
        }
    }
    
    private func sendVideo(_ data: Data, ext: String) throws {
        let fileName = "\(String().random(8)).\(ext)"
        let localPath = IMCoreManager.shared.storageModule
            .allocSessionFilePath((self.session?.id)!, fileName, IMFileFormat.Video.rawValue)
        try IMCoreManager.shared.storageModule.saveMediaDataInto(localPath, data)
        let videoData = IMVideoMsgData()
        videoData.path = localPath
        self.sendMessage(MsgType.VIDEO.rawValue, videoData)
    }
    
    private func sendImage(_ data: Data, ext: String) throws {
        let fileName = "\(String().random(8)).\(ext)"
        let localPath = IMCoreManager.shared.storageModule
            .allocSessionFilePath((self.session?.id)!, fileName, IMFileFormat.Image.rawValue)
        try IMCoreManager.shared.storageModule.saveMediaDataInto(localPath, data)
        let imageData = IMImageMsgData(width: nil, height: nil, path: localPath, thumbnailPath: nil)
        self.sendMessage(MsgType.IMAGE.rawValue, imageData)
    }
    
    func previewMessage(_ msg: Message, _ position: Int,  _ originView: UIView) {
        if msg.type == MsgType.Audio.rawValue {
            guard let cp = IMUIManager.shared.contentProvider else {
                return
            }
            if (msg.data != nil) {
                do {
                    let data = try JSONDecoder().decode(
                        IMAudioMsgData.self,
                        from: msg.data!.data(using: .utf8) ?? Data())
                    if (data.path != nil) {
                        let realPath = IMCoreManager.shared.storageModule.sandboxFilePath(data.path!)
                        let success = cp.startPlayAudio(path: realPath) {
                            db, duration, path, stopped in
                        }
                        if (!success) {
                            
                        }
                    }
                } catch {
                    DDLogError("previewMessage audio \(error)")
                }
            }
        } else if msg.type == MsgType.IMAGE.rawValue || msg.type == MsgType.VIDEO.rawValue {
            var ay = [Message]()
            ay.append(contentsOf: self.fetchMoreMessage(msg.msgId, msg.sessionId, true, 5))
            let current = msg
            ay.append(current)
            ay.append(contentsOf: self.fetchMoreMessage(msg.msgId, msg.sessionId, false, 5))
            IMUIManager.shared.contentPreviewer?.previewMessage(self, items: ay, view: originView, defaultId: msg.id)
        }
    }
    
    private func fetchMoreMessage(_ msgId: Int64, _ sessionId: Int64, _ before: Bool, _ count: Int) -> [Message] {
        do {
            let types = [MsgType.IMAGE.rawValue, MsgType.VIDEO.rawValue]
            let msgDao = IMCoreManager.shared.database.messageDao
            var messages: [Message]
            if before {
                messages = try msgDao.findOlderMessages(msgId, types, sessionId, count)
                messages = messages.reversed()
            } else {
                messages = try msgDao.findNewerMessages(msgId, types, sessionId, count)
            }
            return messages
        } catch {
            DDLogError(error)
        }
        return []
    }

    
}

