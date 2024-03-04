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

class IMMessageViewController: BaseViewController {
    
    var session: Session? = nil
    private var containerView = UIView()
    private var messageLayout = IMMessageLayout()
    private var inputLayout = IMInputLayout()
    private var bottomPanelLayout = IMBottomPanelLayout()
    private var msgSelectedLayout = IMMessageSelectedLayout()
    private var keyboardShow = false
    private var memberMap = [Int64: (User, SessionMember?)]()
    
    deinit {
        DDLogDebug("IMMessageViewController, de init")
        unregisterMsgEvent()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.init(hex: "#F0F0F0")
        self.showSessionTitle()
        self.setupView()
        self.registerMsgEvent()
        self.registerKeyboardEvent()
        self.messageLayout.loadMessages()
//        self.fetchSessionMembers()
    }
    
    private func showSessionTitle() {
        guard let session = self.session else {
            return
        }
        self.setTitle(title: session.name)
        if (session.type == SessionType.Single.rawValue) {
            IMCoreManager.shared.userModule.queryUser(id: session.entityId)
                .compose(RxTransformer.shared.io2Main())
                .subscribe(onNext: { [weak self] user in
                    self?.setTitle(title: user.nickname)
                }).disposed(by: self.disposeBag)
        }
    }
    
    override func hasAddMenu() -> Bool {
        return true
    }
    
    override func hasSearchMenu() -> Bool {
        return true
    }
    
    override func menuImages(menu: String) -> UIImage? {
        if menu == "search" {
            return UIImage(named: "ic_titlebar_call")?.scaledToSize(CGSize.init(width: 24, height: 24))
        } else {
            return UIImage(named: "ic_titlebar_more")?.scaledToSize(CGSize.init(width: 24, height: 24))
        }
    }
    
    private func fetchSessionMembers() {
        guard let sessionId = self.session?.id else {
            return
        }
        IMCoreManager.shared.messageModule.querySessionMembers(sessionId)
            .flatMap { members in
                var ids = Set<Int64>()
                for m in members {
                    ids.insert(m.userId)
                }
                return IMCoreManager.shared.userModule.queryUsers(ids: ids)
                    .flatMap { userMap in
                        var memberMap = [Int64: (User, SessionMember?)]()
                        for (k, v) in userMap {
                            var member: SessionMember? = nil
                            for m in members {
                                if (m.userId == k) {
                                    member = m
                                    break
                                }
                            }
                            memberMap[k] = (v, member)
                        }
                        return Observable.just(memberMap)
                    }
            }.compose(RxTransformer.shared.io2Main())
            .subscribe(onNext: { [weak self] map in
                self?.updateSessionMember(map)
            }).disposed(by: self.disposeBag)
    }
    
    private func updateSessionMember(_ map: [Int64: (User, SessionMember?)]) {
        map.forEach { (key: Int64, value: (User, SessionMember?)) in
            self.memberMap[key] = value
        }
        self.messageLayout.refreshMessageUserInfo()
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.isKeyboardShowing() {
            _ = self.closeKeyboard()
        }
    }
    
    override func onMenuClick(menu: String) {
        guard let session = self.session else {
            return
        }
        if (session.type == SessionType.Single.rawValue) {
            if menu == "search" {
                IMUIManager.shared.pageRouter?.openLiveCall(controller: self, session: session)
            } else {
                IMCoreManager.shared.userModule.queryUser(id: session.entityId)
                    .compose(RxTransformer.shared.io2Main())
                    .subscribe(onNext: { user in
                        IMUIManager.shared.pageRouter?.openUserPage(controller: self, user: user)
                    }).disposed(by: self.disposeBag)
            }
        } else if (session.type == SessionType.Group.rawValue ||
                   session.type == SessionType.SuperGroup.rawValue
        ) {
            if menu == "search" {
            } else {
                IMCoreManager.shared.groupModule.findById(id: session.entityId)
                    .compose(RxTransformer.shared.io2Main())
                    .subscribe(onNext: { group in
                        if let g = group  {
                            IMUIManager.shared.pageRouter?.openGroupPage(controller: self, group: g)
                        }
                    }).disposed(by: self.disposeBag)
            }
        }
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
        self.bottomPanelLayout.backgroundColor = UIColor.init(hex: "#F0F0F0")
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
        self.inputLayout.backgroundColor = UIColor.init(hex: "#F0F0F0")
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
        self.msgSelectedLayout.backgroundColor = UIColor.init(hex: "#F0F0F0")
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
        self.messageLayout.backgroundColor = UIColor.init(hex: "#F8F8F8")
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
        self.moveKeyboard(true, height, duration)
    }
    
    @objc func keyboardWillDisappear(note: NSNotification){
        let animation = note.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey]
        let duration: Double = (animation as AnyObject).doubleValue
        let height = self.bottomPanelLayout.getLayoutHeight()
        self.moveKeyboard(false, height, duration)
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
    
    func moveKeyboard(_ isKeyboardShow: Bool, _ height: CGFloat, _ duration: Double) {
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
    
    private func showReplyMessage(_ msg: Message) {
        self.inputLayout.showReplyMessage(msg)
        self.messageLayout.scrollToBottom()
    }
    
    private func dismissReplyMessage() {
        self.inputLayout.clearReplyMessage()
    }
    
    private func sendVideo(_ data: Data, ext: String) throws {
        let fileName = "\(String().random(8)).\(ext)"
        let localPath = IMCoreManager.shared.storageModule
            .allocSessionFilePath((self.session?.id)!, fileName, IMFileFormat.Video.rawValue)
        try IMCoreManager.shared.storageModule.saveMediaDataInto(localPath, data)
        let videoData = IMVideoMsgData()
        videoData.path = localPath
        self.sendMessage(MsgType.Video.rawValue, nil, videoData)
    }
    
    private func sendImage(_ data: Data, ext: String) throws {
        let fileName = "\(String().random(8)).\(ext)"
        let localPath = IMCoreManager.shared.storageModule
            .allocSessionFilePath((self.session?.id)!, fileName, IMFileFormat.Image.rawValue)
        try IMCoreManager.shared.storageModule.saveMediaDataInto(localPath, data)
        let imageData = IMImageMsgData(width: nil, height: nil, path: localPath, thumbnailPath: nil)
        self.sendMessage(MsgType.Image.rawValue, nil, imageData)
    }
    
    private func fetchMoreMessage(_ msgId: Int64, _ sessionId: Int64, _ before: Bool, _ count: Int) -> [Message] {
        do {
            let types = [MsgType.Image.rawValue, MsgType.Video.rawValue]
            let msgDao = IMCoreManager.shared.database.messageDao()
            var messages: [Message]
            if before {
                messages = try msgDao.findOlderMessages(msgId, types, sessionId, count)
                messages = messages.reversed()
            } else {
                messages = try msgDao.findNewerMessages(msgId, types, sessionId, count)
            }
            return messages
        } catch {
            DDLogError("\(error)")
        }
        return []
    }
}

extension IMMessageViewController: IMMsgSender, IMMsgPreviewer, IMSessionMemberAtDelegate {
    
    func viewController() -> UIViewController {
        return self
    }
    
    /// 获取session信息
    func getSession() -> Session? {
        return self.session
    }
    
    /// 重发消息
    func resendMessage(_ msg: Message) {
        IMCoreManager.shared.messageModule.getMsgProcessor(msg.type).resend(msg)
    }
    
    
    /// 发送消息
    func sendMessage(_ type: Int, _ body: Codable?, _ data: Codable? = nil, _ atUser: String? = nil) {
        guard let sessionId = self.session?.id else {
            return
        }
        var referMsgId :Int64? = nil
        if let replyMsg = self.inputLayout.getReplyMessage() {
            referMsgId = replyMsg.msgId
        }
        IMCoreManager.shared.messageModule.sendMessage(sessionId, type, body, data, atUser, referMsgId, { _, _ in
        })
        
        self.inputLayout.clearReplyMessage()
    }
    
    /// 发送输入框内容
    func sendInputContent() {
        return self.inputLayout.sendInputContent()
    }
    
    /// 输入框添加内容
    func addInputContent(text: String) {
        self.inputLayout.addInputText(text)
    }
    
    /// 删除输入框内容
    func deleteInputContent(count: Int) {
        self.inputLayout.deleteInputContent(count)
    }
    
    
    /// 选择照片
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
                DDLogDebug("\(error)")
            }
        }
    }
    
    
    /// 相机拍照
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
                DDLogError("\(error)")
            }
        }
    }
    
    /// 移动到最新消息
    func moveToLatestMessage() {
        self.messageLayout.scrollToBottom()
    }
    
    /// 打开底部面本:position: 1表情 2更多
    func showBottomPanel(_ type: Int) {
        self.bottomPanelLayout.showBottomPanel(type)
    }
    
    /// 关闭底部面板
    func closeBottomPanel() {
        self.bottomPanelLayout.closeBottomPanel()
    }
    
    
    /// 顶起常驻视图（消息列表+底部输入框）
    func moveUpAlwaysShowView(_ isKeyboardShow: Bool, _ height: CGFloat, _ duration: Double) {
        self.moveKeyboard(isKeyboardShow, height, duration)
    }
    
    /// 打开键盘
    @discardableResult func openKeyboard() -> Bool {
        self.inputLayout.openKeyboard()
    }
    
    
    /// 键盘是否显示
    func isKeyboardShowing() -> Bool {
        return self.keyboardShow
    }
    
    
    /// 关闭键盘
    @discardableResult func closeKeyboard() -> Bool {
        self.inputLayout.closeKeyboard()
    }
    
    
    /// 打开/关闭多选消息视图
    func setSelectMode(_ selected: Bool, message: Message?) {
        if (selected) {
            self.messageLayout.setSelectMode(selected, message: message)
            self.msgSelectedLayout.isHidden = false
        } else {
            self.messageLayout.setSelectMode(selected)
            self.msgSelectedLayout.isHidden = true
        }
    }
    
    /// 删除多选视图选中的消息
    func deleteSelectedMessages() {
        let messages = self.messageLayout.getSelectMessages()
        if (messages.count > 0 && session != nil) {
            IMCoreManager.shared.messageModule
                .deleteMessages(session!.id, Array(messages), true)
                .compose(RxTransformer.shared.io2Main())
                .subscribe(onError: { error in
                    DDLogError("deleteSelectedMessages \(error)")
                }, onCompleted: {
                    DDLogInfo("deleteSelectedMessages success ")
                }).disposed(by: self.disposeBag)
        }
    }
    
    /// 设置已读消息
    func readMessage(_ message: Message) {
        IMCoreManager.shared.messageModule
            .sendMessage(message.sessionId, MsgType.Read.rawValue, nil, nil, nil, message.msgId, nil)
    }
    
    /// 弹出消息操作面板弹窗
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
    
    /// show loading
    func showSenderLoading(text: String) {
        self.showLoading(text: text)
    }
    
    /// dismiss Loading
    func dismissSenderLoading() {
        self.dismissLoading()
    }
    
    /// show message
    func showSenderMessage(text: String, success: Bool) {
        self.showToast(text, success)
    }
    
    /// 发送消息到session forwardType 0单条转发, 1合并转发
    func forwardMessageToSession(messages: Array<Message>, forwardType: Int) {
        IMSessionChooseViewController.popup(vc: self, forwardType: forwardType, messages: messages)
    }
    
    /// 转发选定的消息 forwardType 0单条转发, 1合并转发
    func forwardSelectedMessages(forwardType: Int) {
        let messages = self.messageLayout.getSelectMessages()
        if (messages.count > 0 && session != nil) {
            IMSessionChooseViewController.popup(vc: self, forwardType: forwardType, messages: Array(messages))
        }
    }
    
    ///  打开at会话成员控制器
    func openAtViewController() {
        guard let session = self.session else {
            return
        }
        if (session.type != SessionType.Group.rawValue &&
            session.type != SessionType.SuperGroup.rawValue
        ) {
            return
        }
        let atSessionMemberController = IMAtSessionMemberController()
        atSessionMemberController.delegate = self
        atSessionMemberController.session = session
        atSessionMemberController.modalPresentationStyle = .custom
        atSessionMemberController.transitioningDelegate = atSessionMemberController
        self.present(atSessionMemberController, animated: true)
    }
    
    ///  添加at会话
    func addAtUser(user: User, sessionMember: SessionMember?) {
        self.inputLayout.addAtSessionMember(user: user, sessionMember: sessionMember)
    }
    
    /// 回复消息
    func replyMessage(msg: Message) {
        self.showReplyMessage(msg)
    }
    
    /// 关闭回复消息
    func closeReplyMessage() {
        self.dismissReplyMessage()
    }
    
    /// 重编辑消息
    func reeditMessage(_ message: Message) {
        self.inputLayout.setReeditMessage(message)
    }
    
    /// 同步获取用户信息
    func syncGetSessionMemberInfo(_ userId: Int64) -> (User, SessionMember?)? {
        return self.memberMap[userId]
    }
    
    /// 设置用户信息
    func saveSessionMemberInfo(_ info: (User, SessionMember?)) {
        self.memberMap[info.0.id] = info
    }
    
    /// 异步获取用户信息
    func asyncGetSessionMemberInfo(_ userId: Int64) -> Observable<(User, SessionMember?)> {
        return IMCoreManager.shared.userModule.queryUser(id: userId)
            .flatMap { [weak self] user in
                if let sessionId = self?.session?.id {
                    let sessionMember = IMCoreManager.shared.database.sessionMemberDao().findSessionMember(sessionId, user.id)
                    return Observable.just((user, sessionMember))
                } else {
                    return Observable.just((user, nil))
                }
            }
    }
    
    func onSessionMemberAt(sessionMember: SessionMember, user: User) {
        self.inputLayout.addAtSessionMember(user: user, sessionMember: sessionMember)
    }
    
    ///  预览消息
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
        } else if msg.type == MsgType.Image.rawValue || msg.type == MsgType.Video.rawValue {
            var ay = [Message]()
            ay.append(contentsOf: self.fetchMoreMessage(msg.msgId, msg.sessionId, true, 5))
            let current = msg
            ay.append(current)
            ay.append(contentsOf: self.fetchMoreMessage(msg.msgId, msg.sessionId, false, 5))
            IMUIManager.shared.contentPreviewer?.previewMessage(self, ay, originView, msg.msgId)
        } else if msg.type == MsgType.Record.rawValue {
            if (session != nil) {
                IMUIManager.shared.contentPreviewer?.previewRecordMessage(self, session!, msg)
            }
        }
    }
    
}
