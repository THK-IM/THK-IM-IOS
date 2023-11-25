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
    private var msgSelectedLayout = IMMessageSelectedLayout()
    private var keyboardShow = false
    private var disposeBag = DisposeBag()
    
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
        self.containerView.addSubview(self.msgSelectedLayout)
        self.msgSelectedLayout.sender = self
        self.msgSelectedLayout.alpha = 1
        self.msgSelectedLayout.backgroundColor = UIColor.init(hex: "e2e2e2")
        self.msgSelectedLayout.isHidden = true
        self.msgSelectedLayout.snp.makeConstraints { [weak self] make in
            guard let sf = self else {
                return
            }
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalTo(sf.bottomPanelLayout.snp.top)
            make.height.equalTo(sf.msgSelectedLayout.getLayoutHeight()) // 高度内部自己计算
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
        
        SwiftEventBus.onMainThread(self, name: IMEvent.BatchMsgDelete.rawValue, handler: { [weak self ]result in
            guard let messages = result?.object as? Array<Message> else {
                return
            }
            guard let sId = self?.session?.id else {
                return
            }
            var deleteMessages = Array<Message>()
            for msg in messages {
                if (msg.sessionId == sId) {
                    deleteMessages.append(msg)
                }
            }
            self?.messageLayout.deleteMessages(deleteMessages)
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
    
    
    func sendMessage(_ type: Int, _ body: Codable?, _ data: Codable?) {
        guard let sessionId = self.session?.id else {
            return
        }
        IMCoreManager.shared.getMessageModule().sendMessage(sessionId, type, body, data, nil, nil, { _, _ in
        })
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
    
    
    func setSelectMode(_ selected: Bool, message: Message?) {
        if (selected) {
            self.messageLayout.setSelectMode(selected, message: message)
            self.msgSelectedLayout.isHidden = false
        } else {
            self.messageLayout.setSelectMode(selected)
            self.msgSelectedLayout.isHidden = true
        }
    }
    
    func deleteSelectedMessages() {
        let messages = self.messageLayout.getSelectMessages()
        if (messages.count > 0 && session != nil) {
            IMCoreManager.shared.getMessageModule()
                .deleteMessages(session!.id, Array(messages), true)
                .compose(RxTransformer.shared.io2Main())
                .subscribe(onError: { error in
                    DDLogError("deleteSelectedMessages \(error)")
                }, onCompleted: {
                    DDLogInfo("deleteSelectedMessages success ")
                }).disposed(by: self.disposeBag)
        }
    }
    
    func readMessage(_ message: Message) {
        IMCoreManager.shared.getMessageModule()
            .sendMessage(message.sessionId, MsgType.READ.rawValue, nil, nil, nil, message.msgId, nil)
    }
    
    
    func popupMessageOperatorPanel(_ view: UIView, _ message: Message) {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let atFrame = view.convert(view.bounds, to: nil)
        let operators = IMUIManager.shared.getMessageOperators(message)
        let rowCount = 5
        let popupWidth = 300
        let popupHeight = (operators.count/rowCount + operators.count%rowCount) * 60
        var y = 0
        if (atFrame.origin.y <= 300 && (atFrame.origin.y + atFrame.size.height) >= (screenHeight - 300)) {
            y = (Int(screenHeight) - popupHeight) / 2
        } else if (atFrame.origin.y > 300) {
            y = Int(atFrame.origin.y) - popupHeight
        } else {
            y = Int(atFrame.origin.y) + Int(atFrame.size.height)
        }
        let frame = CGRect(x: (Int(screenWidth)-popupWidth)/2, y: y, width: popupWidth, height: popupHeight)
        let popupView = IMMessageOperatorPopupView(frame: frame)
        popupView.show(rowCount, operators, self, message)
    }
    
    
    func showLoading(text: String) {
        
    }
    
    func dismissLoading() {
        
    }
    
    func showMessage(text: String, success: Bool) {
        
    }
    
    func forwardMessageToSession(messages: Array<Message>, forwardType: Int) {
        IMSessionChooseViewController.popup(vc: self, forwardType: forwardType, messages: messages)
    }
    
    func forwardSelectedMessages(forwardType: Int) {
        let messages = self.messageLayout.getSelectMessages()
        if (messages.count > 0 && session != nil) {
            IMSessionChooseViewController.popup(vc: self, forwardType: forwardType, messages: Array(messages))
        }
    }
    
    private func sendVideo(_ data: Data, ext: String) throws {
        let fileName = "\(String().random(8)).\(ext)"
        let localPath = IMCoreManager.shared.storageModule
            .allocSessionFilePath((self.session?.id)!, fileName, IMFileFormat.Video.rawValue)
        try IMCoreManager.shared.storageModule.saveMediaDataInto(localPath, data)
        let videoData = IMVideoMsgData()
        videoData.path = localPath
        self.sendMessage(MsgType.VIDEO.rawValue, nil, videoData)
    }
    
    private func sendImage(_ data: Data, ext: String) throws {
        let fileName = "\(String().random(8)).\(ext)"
        let localPath = IMCoreManager.shared.storageModule
            .allocSessionFilePath((self.session?.id)!, fileName, IMFileFormat.Image.rawValue)
        try IMCoreManager.shared.storageModule.saveMediaDataInto(localPath, data)
        let imageData = IMImageMsgData(width: nil, height: nil, path: localPath, thumbnailPath: nil)
        self.sendMessage(MsgType.IMAGE.rawValue, nil, imageData)
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

