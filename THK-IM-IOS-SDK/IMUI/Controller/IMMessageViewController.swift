//
//  IMMessageViewController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/28.
//

import CocoaLumberjack
import CoreServices
import Foundation
import ImageIO
import Photos
import RxGesture
import RxSwift
import SnapKit
import UIKit

open class IMMessageViewController: BaseViewController {

    public var session: Session? = nil
    public let containerView = UIView()
    public let messageLayout = IMMessageLayout()
    public let inputLayout = IMInputLayout()
    public let bottomPanelLayout = IMBottomPanelLayout()
    public var msgSelectedLayout = IMMessageSelectedLayout()
    public var atMsgTipsView = IMMsgLabelView()
    public var newMsgTipsView = IMMsgLabelView()
    public var unReadMsgTipsView = IMMsgLabelView()
    public var keyboardShow = false
    public var memberMap = [Int64: (User, SessionMember?)]()
    public var atMsgs = [Message]()
    public var showInput = true

    deinit {
        DDLogDebug("IMMessageViewController, de init")
        unregisterMsgEvent()
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        self.memberMap[-1] = (User.all, nil)
        self.showSessionTitle()
        self.setupView()
        self.registerMsgEvent()
        self.registerKeyboardEvent()
        self.fetchSessionMembers()
        self.initTipsView()
    }

    open func showSessionTitle() {
        guard let session = self.session else {
            return
        }
        self.setTitle(title: session.name)
        if session.type == SessionType.Single.rawValue {
            IMCoreManager.shared.userModule.queryUser(id: session.entityId)
                .compose(RxTransformer.shared.io2Main())
                .subscribe(onNext: { [weak self] user in
                    self?.setTitle(title: user.nickname)
                }).disposed(by: self.disposeBag)
        }
    }

    open override func hasAddMenu() -> Bool {
        return true
    }

    open override func hasSearchMenu() -> Bool {
        return true
    }

    open override func menuImages(menu: String) -> UIImage? {
        if menu == "search" {
            return ResourceUtils.loadImage(named: "ic_titlebar_call")?.scaledToSize(
                CGSize.init(width: 24, height: 24))
        } else {
            return ResourceUtils.loadImage(named: "ic_titlebar_more")?.scaledToSize(
                CGSize.init(width: 24, height: 24))
        }
    }

    private func fetchSessionMembers() {
        guard let sessionId = self.session?.id else {
            return
        }
        let online = IMCoreManager.shared.signalModule.getSignalStatus() == SignalStatus.Connected
        IMCoreManager.shared.messageModule.querySessionMembers(sessionId, online)
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
                                if m.userId == k {
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
                self?.messageLayout.loadMessages()
            }).disposed(by: self.disposeBag)
    }

    private func updateSessionMember(_ map: [Int64: (User, SessionMember?)]) {
        map.forEach { (key: Int64, value: (User, SessionMember?)) in
            self.memberMap[key] = value
        }
        self.messageLayout.refreshMessageUserInfo()
    }

    open override func onMenuClick(menu: String) {
        guard let session = self.session else {
            return
        }
        if session.type == SessionType.Single.rawValue {
            if menu == menuItemTagSearch {
                IMUIManager.shared.pageRouter?.openLiveCall(controller: self, session: session)
            } else {
                IMCoreManager.shared.userModule.queryUser(id: session.entityId)
                    .compose(RxTransformer.shared.io2Main())
                    .subscribe(onNext: { user in
                        IMUIManager.shared.pageRouter?.openUserPage(
                            controller: self, user: user, session: session)
                    }).disposed(by: self.disposeBag)
            }
        } else if session.type == SessionType.Group.rawValue
            || session.type == SessionType.SuperGroup.rawValue
        {
            if menu == menuItemTagSearch {
            } else {
                IMCoreManager.shared.groupModule.findById(id: session.entityId)
                    .compose(RxTransformer.shared.io2Main())
                    .subscribe(onNext: { group in
                        IMUIManager.shared.pageRouter?.openGroupPage(
                            controller: self, group: group, session: session)
                    }).disposed(by: self.disposeBag)
            }
        }
    }

    @objc open override func viewTouched() {
    }

    private func setupView() {
        self.view.addSubview(containerView)
        if let session = self.session {
            showInput = session.functionFlag > 0
        }
        containerView.backgroundColor = IMUIManager.shared.uiResourceProvider?.panelBgColor()
        let top = getTitleBarHeight()
        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(top)
            make.bottom.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        containerView.clipsToBounds = true

        if !showInput {
            let bottom = getSafeBottomHeight()
            // 多选msg视图
            self.msgSelectedLayout.sender = self
            self.msgSelectedLayout.height += Int(bottom)
            self.containerView.addSubview(self.msgSelectedLayout)
            self.msgSelectedLayout.isHidden = true
            self.msgSelectedLayout.snp.makeConstraints { make in
                make.left.equalToSuperview()
                make.right.equalToSuperview()
                make.bottom.equalToSuperview()
                make.height.equalTo(0)
            }
            self.msgSelectedLayout.backgroundColor = IMUIManager.shared.uiResourceProvider?
                .panelBgColor()

            // 消息视图，在输入框之上，铺满alwaysShowView
            self.messageLayout.sender = self
            self.messageLayout.previewer = self
            self.containerView.addSubview(self.messageLayout)
            self.messageLayout.session = self.session
            self.messageLayout.snp.makeConstraints { [weak self] make in
                guard let sf = self else {
                    return
                }
                make.left.equalToSuperview()
                make.right.equalToSuperview()
                make.top.equalToSuperview()
                make.bottom.equalTo(sf.msgSelectedLayout.snp.top)
            }
            self.messageLayout.backgroundColor = IMUIManager.shared.uiResourceProvider?
                .layoutBgColor()
        } else {
            self.bottomPanelLayout.sender = self
            self.containerView.addSubview(self.bottomPanelLayout)
            self.bottomPanelLayout.snp.makeConstraints { [weak self] make in
                guard let sf = self else {
                    return
                }
                make.left.equalToSuperview()
                make.right.equalToSuperview()
                make.bottom.equalToSuperview().offset(
                    -UIApplication.shared.windows[0].safeAreaInsets.bottom)
                make.height.equalTo(sf.bottomPanelLayout.getLayoutHeight())  // 高度内部自己计算
            }

            // 输入框等布局
            self.inputLayout.sender = self
            self.containerView.addSubview(self.inputLayout)

            self.inputLayout.resetLayout()
            DispatchQueue.main.asyncAfter(
                deadline: .now() + 0.1,
                execute: { [weak self] in
                    if let draft = self?.session?.draft {
                        self?.inputLayout.addInputText(draft)
                    }
                })

            self.inputLayout.snp.makeConstraints { [weak self] make in
                guard let sf = self else {
                    return
                }
                make.left.equalToSuperview()
                make.right.equalToSuperview()
                make.bottom.equalTo(sf.bottomPanelLayout.snp.top)
                make.height.greaterThanOrEqualTo(sf.inputLayout.getLayoutHeight())  // 高度内部自己计算
            }

            // 多选msg视图
            self.msgSelectedLayout.sender = self
            self.containerView.addSubview(self.msgSelectedLayout)
            self.msgSelectedLayout.isHidden = true
            self.msgSelectedLayout.snp.makeConstraints { [weak self] make in
                guard let sf = self else {
                    return
                }
                make.left.equalToSuperview()
                make.right.equalToSuperview()
                make.bottom.equalTo(sf.bottomPanelLayout.snp.top)
                make.height.equalTo(sf.msgSelectedLayout.getLayoutHeight())  // 高度内部自己计算
            }
            self.msgSelectedLayout.backgroundColor = IMUIManager.shared.uiResourceProvider?
                .panelBgColor()

            // 消息视图，在输入框之上，铺满alwaysShowView
            self.messageLayout.sender = self
            self.messageLayout.previewer = self
            self.containerView.addSubview(self.messageLayout)
            self.messageLayout.session = self.session
            self.messageLayout.snp.makeConstraints { [weak self] make in
                guard let sf = self else {
                    return
                }
                make.left.equalToSuperview()
                make.right.equalToSuperview()
                make.top.equalToSuperview()
                make.bottom.equalTo(sf.inputLayout.snp.top)
            }
            self.messageLayout.backgroundColor = IMUIManager.shared.uiResourceProvider?
                .layoutBgColor()
        }
    }

    open func initTipsView() {
        // 未读消息提醒
        self.unReadMsgTipsView.isUserInteractionEnabled = true
        self.unReadMsgTipsView.textColor =
            IMUIManager.shared.uiResourceProvider?.tintColor() ?? UIColor.init(hex: "#1390f4")
        self.unReadMsgTipsView.font = UIFont.boldSystemFont(ofSize: 13)
        self.unReadMsgTipsView.backgroundColor = IMUIManager.shared.uiResourceProvider?
            .panelBgColor()
        self.unReadMsgTipsView.layer.cornerRadius = 6
        self.unReadMsgTipsView.layer.masksToBounds = true
        self.unReadMsgTipsView.padding = UIEdgeInsets.init(
            top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
        self.containerView.addSubview(self.unReadMsgTipsView)
        self.unReadMsgTipsView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(self.messageLayout.snp.top).offset(40)
        }
        self.unReadMsgTipsView.rx.tapGesture().when(.ended)
            .subscribe { [weak self] _ in
                self?.unReadMsgTipsView.isHidden = true
                self?.messageLayout.scrollToUnReadMsg()
            }.disposed(by: self.disposeBag)
        self.unReadMsgTipsView.isHidden = true
        DispatchQueue.main.asyncAfter(
            deadline: .now() + 0.5,
            execute: { [weak self] in
                let unreadCount = self?.session?.unreadCount ?? 0
                if unreadCount > 0 {
                    self?.unReadMsgTipsView.text = String.init(
                        format: ResourceUtils.loadString("x_message_unread"), unreadCount)
                    self?.unReadMsgTipsView.isHidden = false
                } else {
                    self?.unReadMsgTipsView.isHidden = true
                }
            })

        // 新消息提醒
        self.newMsgTipsView.isUserInteractionEnabled = true
        self.newMsgTipsView.textColor =
            IMUIManager.shared.uiResourceProvider?.tintColor() ?? UIColor.init(hex: "#1390f4")
        self.newMsgTipsView.text = ResourceUtils.loadString("new_message_tips")
        self.newMsgTipsView.font = UIFont.boldSystemFont(ofSize: 13)
        self.newMsgTipsView.backgroundColor = IMUIManager.shared.uiResourceProvider?
            .panelBgColor()
        self.newMsgTipsView.layer.cornerRadius = 6
        self.newMsgTipsView.layer.masksToBounds = true
        self.newMsgTipsView.padding = UIEdgeInsets.init(
            top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
        self.containerView.addSubview(self.newMsgTipsView)
        self.newMsgTipsView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(self.messageLayout.snp.top).offset(100)
        }
        self.newMsgTipsView.rx.tapGesture().when(.ended)
            .subscribe { [weak self] _ in
                self?.messageLayout.scrollToBottom()
            }.disposed(by: self.disposeBag)
        self.newMsgTipsView.isHidden = true

        // AT提醒
        self.atMsgTipsView.isUserInteractionEnabled = true
        self.atMsgTipsView.textColor =
            IMUIManager.shared.uiResourceProvider?.tintColor() ?? UIColor.init(hex: "#1390f4")
        self.atMsgTipsView.font = UIFont.boldSystemFont(ofSize: 13)
        self.atMsgTipsView.backgroundColor = IMUIManager.shared.uiResourceProvider?
            .panelBgColor()
        self.atMsgTipsView.layer.cornerRadius = 6
        self.atMsgTipsView.layer.masksToBounds = true
        self.atMsgTipsView.padding = UIEdgeInsets.init(top: 8.0, left: 8.0, bottom: 8.0, right: 8.0)
        self.containerView.addSubview(self.atMsgTipsView)
        self.atMsgTipsView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-20)
            make.top.equalTo(self.messageLayout.snp.top).offset(140)
        }
        self.atMsgTipsView.rx.tapGesture().when(.ended)
            .subscribe { [weak self] _ in
                self?.onAtTipsViewClick()
            }.disposed(by: self.disposeBag)

        if let session = self.session {
            if session.unreadCount > 0 {
                Observable.just("").flatMap { _ in
                    let atMsgs = IMCoreManager.shared.database.messageDao()
                        .findSessionAtMeUnreadMessages(session.id)
                    return Observable.just(atMsgs)
                }.compose(RxTransformer.shared.io2Main())
                    .subscribe { [weak self] msgs in
                        self?.atMsgs.append(contentsOf: msgs)
                        self?.updateAtTipsView()
                    }.disposed(by: self.disposeBag)
            }
        }
        self.updateAtTipsView()

    }

    private func updateUnreadTipsView() {
        let unreadCount = self.session?.unreadCount ?? 0
        if unreadCount > 0 {
            if self.unReadMsgTipsView.isHidden == false {
                self.unReadMsgTipsView.text = String.init(
                    format: ResourceUtils.loadString("x_message_unread"), unreadCount)
            }
        } else {
            self.unReadMsgTipsView.isHidden = true
        }
    }

    private func updateAtTipsView() {
        if self.atMsgs.count <= 0 {
            self.atMsgTipsView.isHidden = true
        } else {
            self.atMsgTipsView.text = String.init(
                format: ResourceUtils.loadString("x_message_at_me"), self.atMsgs.count)
            self.atMsgTipsView.isHidden = false
        }
    }

    private func onAtTipsViewClick() {
        if self.atMsgs.count > 0 {
            let msg = self.atMsgs.remove(at: 0)
            updateAtTipsView()
            self.messageLayout.scrollToMsg(msg)
        }
    }

    private func getSafeBottomHeight() -> CGFloat {
        guard let window = UIApplication.shared.windows.first else {
            return 0
        }
        return window.safeAreaInsets.bottom
    }

    func registerKeyboardEvent() {
        let showInput = (self.session?.functionFlag ?? 0) > 0
        if showInput {
            NotificationCenter.default.addObserver(
                self, selector: #selector(keyboardWillAppear),
                name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.addObserver(
                self, selector: #selector(keyboardWillDisappear),
                name: UIResponder.keyboardWillHideNotification, object: nil)
        }
    }

    @objc func keyboardWillAppear(note: NSNotification) {
        let keyboard = note.userInfo![UIResponder.keyboardFrameEndUserInfoKey]
        let keyboardHeight: CGFloat = (keyboard as AnyObject).cgRectValue.size.height
        let animation = note.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey]
        let duration: Double = (animation as AnyObject).doubleValue

        self.keyboardShow = true
        let height = keyboardHeight
        self.moveKeyboard(true, height, duration)
    }

    @objc func keyboardWillDisappear(note: NSNotification) {
        let animation = note.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey]
        let duration: Double = (animation as AnyObject).doubleValue
        let height = self.bottomPanelLayout.getLayoutHeight()
        self.moveKeyboard(false, height, duration)
    }

    func registerMsgEvent() {
        SwiftEventBus.onMainThread(
            self, name: IMEvent.BatchMsgNew.rawValue,
            handler: { [weak self] result in
                guard let tuple = result?.object as? (Int64, [Message]) else {
                    return
                }
                if tuple.0 != self?.session?.id {
                    return
                }
                self?.messageLayout.insertMessages(tuple.1)
            })

        SwiftEventBus.onMainThread(
            self, name: IMEvent.MsgNew.rawValue,
            handler: { [weak self] result in
                guard let msg = result?.object as? Message else {
                    return
                }
                guard let sf = self else {
                    return
                }
                if msg.sessionId != sf.session?.id {
                    return
                }
                DDLogDebug("IMEvent: \(IMEvent.MsgNew.rawValue)")
                if (msg.operateStatus & MsgOperateStatus.ClientRead.rawValue == 0) && msg.isAtMe() {
                    var contained = false
                    sf.atMsgs.forEach { m in
                        if m.msgId == msg.msgId {
                            contained = true
                        }
                    }
                    if !contained {
                        sf.atMsgs.append(msg)
                        sf.updateAtTipsView()
                    }
                }
                sf.messageLayout.insertMessage(msg)
            })
        SwiftEventBus.onMainThread(
            self, name: IMEvent.MsgUpdate.rawValue,
            handler: { [weak self] result in
                guard let msg = result?.object as? Message else {
                    return
                }
                guard let sf = self else {
                    return
                }
                if msg.sessionId != self?.session?.id {
                    return
                }
                DDLogDebug("IMEvent: \(IMEvent.MsgUpdate.rawValue)")
                if (msg.operateStatus & MsgOperateStatus.ClientRead.rawValue == 0) && msg.isAtMe() {
                    var contained = false
                    sf.atMsgs.forEach { m in
                        if m.msgId == msg.msgId {
                            contained = true
                        }
                    }
                    if !contained {
                        sf.atMsgs.append(msg)
                        sf.updateAtTipsView()
                    }
                }
                sf.messageLayout.insertMessage(msg)
            })

        SwiftEventBus.onMainThread(
            self, name: IMEvent.MsgDelete.rawValue,
            handler: { [weak self] result in
                guard let msg = result?.object as? Message else {
                    return
                }
                guard let sf = self else {
                    return
                }
                if msg.sessionId != self?.session?.id {
                    return
                }
                sf.atMsgs.removeAll { atMsg in
                    return atMsg.msgId == msg.msgId
                }
                sf.updateAtTipsView()
                DDLogDebug("IMEvent: \(IMEvent.MsgUpdate.rawValue)")
                self?.messageLayout.deleteMessage(msg)
            })

        SwiftEventBus.onMainThread(
            self, name: IMEvent.BatchMsgDelete.rawValue,
            handler: { [weak self] result in
                guard let messages = result?.object as? [Message] else {
                    return
                }
                guard let sId = self?.session?.id else {
                    return
                }
                var deleteMessages = [Message]()
                for msg in messages {
                    if msg.sessionId == sId {
                        deleteMessages.append(msg)
                    }
                }
                self?.messageLayout.deleteMessages(deleteMessages)
            })

        SwiftEventBus.onMainThread(
            self, name: IMEvent.SessionMessageClear.rawValue,
            handler: { [weak self] result in
                guard let session = result?.object as? Session else {
                    return
                }
                guard let sId = self?.session?.id else {
                    return
                }
                if sId != session.id {
                    return
                }
                self?.messageLayout.clearMessage()
            })

        SwiftEventBus.onMainThread(
            self, name: IMEvent.SessionNew.rawValue,
            handler: { [weak self] result in
                guard let session = result?.object as? Session else {
                    return
                }
                self?.updateSession(session)
            })

        SwiftEventBus.onMainThread(
            self, name: IMEvent.SessionUpdate.rawValue,
            handler: { [weak self] result in
                guard let session = result?.object as? Session else {
                    return
                }
                self?.updateSession(session)
            })

    }

    func unregisterMsgEvent() {
        SwiftEventBus.unregister(self)
    }

    private func updateSession(_ s: Session) {
        if self.session?.id != s.id {
            return
        }
        self.session?.merge(s)
        self.session?.unreadCount = s.unreadCount
        self.updateUnreadTipsView()
        self.inputLayout.onSessionUpdate()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        _ = inputLayout.endEditing(true)
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.isKeyboardShowing() {
            _ = self.closeKeyboard()
        }
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        guard let session = self.session else {
            return
        }
        if let content = self.inputLayout.getInputContent() {
            Observable.just(content).flatMap { draft in
                if session.draft != draft {
                    try? IMCoreManager.shared.database.sessionDao().updateSessionDraft(
                        session.id, draft)
                    if let session = try? IMCoreManager.shared.database.sessionDao().findById(
                        session.id)
                    {
                        SwiftEventBus.post(IMEvent.SessionUpdate.rawValue, sender: session)
                    }
                }
                return Observable.just(true)
            }.compose(RxTransformer.shared.io2Main())
                .subscribe { _ in

                }.disposed(by: self.disposeBag)
        }

    }

    func moveKeyboard(_ isKeyboardShow: Bool, _ height: CGFloat, _ duration: Double) {
        self.inputLayout.onKeyboardChange(isKeyboardShow, duration, height)
        if height > 0 {
            self.bottomPanelLayout.onKeyboardChange(isKeyboardShow, duration, height)
        }
        self.bottomPanelLayout.snp.updateConstraints { make in
            let offset = height == 0 ? -UIApplication.shared.windows[0].safeAreaInsets.bottom : 0
            make.height.equalTo(height)
            make.bottom.equalToSuperview().offset(offset)
        }
        UIView.animate(
            withDuration: duration,
            animations: { [weak self] in
                guard let sf = self else {
                    return
                }
                if height > 0 {
                    sf.messageLayout.layoutResize(
                        height - UIApplication.shared.windows[0].safeAreaInsets.bottom)
                } else {
                    sf.messageLayout.layoutResize(height)
                }
                sf.containerView.layoutIfNeeded()
            },
            completion: { [weak self] _ in
                if height <= 0 {
                    self?.bottomPanelLayout.onKeyboardChange(isKeyboardShow, duration, height)
                }
            })
    }

    private func showReplyMessage(_ msg: Message) {
        self.inputLayout.showReplyMessage(msg)
        //        self.messageLayout.scrollToBottom()
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

    private func fetchMoreMessage(_ msgId: Int64, _ sessionId: Int64, _ before: Bool, _ count: Int)
        -> [Message]
    {
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

    open func onMsgClick(_ msg: Message, _ position: Int, _ originView: UIView) {
        if msg.type == MsgType.Audio.rawValue {
            guard let cp = IMUIManager.shared.contentProvider else {
                return
            }
            if msg.data != nil {
                do {
                    let data = try JSONDecoder().decode(
                        IMAudioMsgData.self,
                        from: msg.data!.data(using: .utf8) ?? Data()
                    )
                    if data.path != nil {
                        let realPath = IMCoreManager.shared.storageModule.sandboxFilePath(
                            data.path!)
                        if let currentPath = cp.currentPlayingPath() {
                            cp.stopPlayAudio()
                            if currentPath == realPath {
                                return
                            }
                        }
                        let success = cp.startPlayAudio(path: realPath) {
                            db, duration, path, stopped in
                        }
                        if success {
                            if msg.operateStatus & MsgOperateStatus.ClientRead.rawValue == 0 {
                                self.readMessage(msg)
                            }
                        } else {
                            showToast(ResourceUtils.loadString("play_failed"))
                        }
                    }
                } catch {
                    showToast(ResourceUtils.loadString("play_failed"))
                }
            }
        } else if msg.type == MsgType.Image.rawValue || msg.type == MsgType.Video.rawValue {
            var ay = [Message]()
            ay.append(contentsOf: self.fetchMoreMessage(msg.msgId, msg.sessionId, true, 5))
            let current = msg
            ay.append(current)
            ay.append(contentsOf: self.fetchMoreMessage(msg.msgId, msg.sessionId, false, 5))
            IMUIManager.shared.contentPreviewer?.previewMessage(
                self, ay, originView, true, msg.msgId)
        } else if msg.type == MsgType.Record.rawValue {
            if session != nil {
                IMUIManager.shared.contentPreviewer?.previewRecordMessage(self, session!, msg)
            }
        }
    }
}

extension IMMessageViewController: IMMsgSender, IMMsgPreviewer, IMSessionMemberAtDelegate {

    /// 提示/关闭有新消息
    public func showNewMsgTipsView(_ show: Bool) {
        self.newMsgTipsView.isHidden = !show
    }

    public func viewController() -> UIViewController {
        return self
    }

    /// 获取session信息
    public func getSession() -> Session? {
        return self.session
    }

    /// 重发消息
    public func resendMessage(_ msg: Message) {
        IMCoreManager.shared.messageModule.getMsgProcessor(msg.type).resend(
            msg,
            { [weak self] _, err in
                if err != nil {
                    self?.showError(err!)
                }
            })
    }

    /// 发送消息
    public func sendMessage(
        _ type: Int, _ body: Codable?, _ data: Codable? = nil, _ atUser: String? = nil
    ) {
        guard let session = self.session else {
            return
        }
        let supportBaseInput =
            IMUIManager.shared.uiResourceProvider?.supportFunction(
                session, IMChatFunction.BaseInput.rawValue) ?? false
        if !supportBaseInput {
            return
        }

        var referMsgId: Int64? = nil
        if let replyMsg = self.inputLayout.getReplyMessage() {
            referMsgId = replyMsg.msgId
        }
        IMCoreManager.shared.messageModule.sendMessage(
            session.id, type, body, data, atUser, referMsgId,
            { [weak self] _, err in
                if err != nil {
                    self?.showError(err!)
                }
            })
        self.inputLayout.clearReplyMessage()
    }

    /// 发送输入框内容
    public func sendInputContent() {
        return self.inputLayout.sendInputContent()
    }

    /// 输入框添加内容
    public func addInputContent(text: String) {
        var uIds = Set<Int64>()
        self.memberMap.forEach { (key: Int64, value: (User, SessionMember?)) in
            uIds.insert(key)
        }
        var atMap = [Int64: (User, SessionMember?)]()
        let atText = AtStringUtils.replaceAtUIdsToNickname(text, uIds) { [weak self] id in
            guard let member = self?.memberMap[id] else {
                return ""
            }
            atMap[member.0.id] = (member.0, member.1)
            return member.1?.noteName ?? member.0.nickname
        }
        self.inputLayout.addInputText(atText, atMap)
    }

    /// 删除输入框内容
    public func deleteInputContent(count: Int) {
        self.inputLayout.deleteInputContent(count)
    }

    /// 选择照片
    public func choosePhoto() {
        guard let cp = IMUIManager.shared.contentProvider else {
            return
        }
        guard let session = self.session else {
            return
        }
        var formats = [IMFileFormat]()
        let supportImage =
            IMUIManager.shared.uiResourceProvider?.supportFunction(
                session, IMChatFunction.Image.rawValue) ?? false
        if supportImage {
            formats.append(IMFileFormat.Image)
        }
        let supportVideo =
            IMUIManager.shared.uiResourceProvider?.supportFunction(
                session, IMChatFunction.Video.rawValue) ?? false
        if supportVideo {
            formats.append(IMFileFormat.Video)
        }
        if formats.count <= 0 {
            return
        }
        cp.pick(controller: self, formats: formats) { [weak self] result, cancel in
            guard let sf = self else {
                return
            }
            do {
                for r in result {
                    if r.mimeType.starts(with: IMFileFormat.Image.rawValue) {
                        if !supportImage {
                            sf.showSenderMessage(
                                text: ResourceUtils.loadString(
                                    "do_not_allow_send_image"), success: false)
                            return
                        }
                        var ext = r.mimeType.replacingOccurrences(
                            of: IMFileFormat.Image.rawValue, with: "")
                        ext = ext.replacingOccurrences(of: "/", with: "")
                        try sf.sendImage(r.data, ext: ext)
                    } else if r.mimeType.starts(with: IMFileFormat.Video.rawValue) {
                        if !supportVideo {
                            sf.showSenderMessage(
                                text: ResourceUtils.loadString(
                                    "do_not_allow_send_video"), success: false)
                            return
                        }
                        var ext = r.mimeType.replacingOccurrences(
                            of: IMFileFormat.Video.rawValue, with: "")
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
    public func openCamera() {
        guard let cp = IMUIManager.shared.contentProvider else {
            return
        }
        guard let session = self.session else {
            return
        }
        var formats = [IMFileFormat]()
        let supportImage =
            IMUIManager.shared.uiResourceProvider?.supportFunction(
                session, IMChatFunction.Image.rawValue) ?? false
        if supportImage {
            formats.append(IMFileFormat.Image)
        }
        let supportVideo =
            IMUIManager.shared.uiResourceProvider?.supportFunction(
                session, IMChatFunction.Video.rawValue) ?? false
        if supportVideo {
            formats.append(IMFileFormat.Video)
        }
        if formats.count <= 0 {
            return
        }
        cp.openCamera(controller: self, formats: formats) { [weak self] result, cancel in
            guard let sf = self else {
                return
            }
            do {
                for r in result {
                    if r.mimeType.starts(with: IMFileFormat.Image.rawValue) {
                        var ext = r.mimeType.replacingOccurrences(
                            of: IMFileFormat.Image.rawValue, with: "")
                        ext = ext.replacingOccurrences(of: "/", with: "")
                        try sf.sendImage(r.data, ext: ext)
                    } else if r.mimeType.starts(with: IMFileFormat.Video.rawValue) {
                        var ext = r.mimeType.replacingOccurrences(
                            of: IMFileFormat.Video.rawValue, with: "")
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
    public func moveToLatestMessage() {
        self.messageLayout.scrollToBottom()
    }

    /// 打开底部面本:position: 1表情 2更多
    public func showBottomPanel(_ type: Int) {
        self.bottomPanelLayout.showBottomPanel(type)
    }

    /// 关闭底部面板
    public func closeBottomPanel() {
        self.bottomPanelLayout.closeBottomPanel()
    }

    /// 顶起常驻视图（消息列表+底部输入框）
    public func moveUpAlwaysShowView(_ isKeyboardShow: Bool, _ height: CGFloat, _ duration: Double)
    {
        self.moveKeyboard(isKeyboardShow, height, duration)
    }

    /// 打开键盘
    @discardableResult public func openKeyboard() -> Bool {
        self.inputLayout.openKeyboard()
    }

    /// 键盘是否显示
    public func isKeyboardShowing() -> Bool {
        return self.keyboardShow
    }

    /// 关闭键盘
    @discardableResult public func closeKeyboard() -> Bool {
        self.inputLayout.closeKeyboard()
    }

    /// 打开/关闭多选消息视图
    public func setSelectMode(_ selected: Bool, message: Message?) {
        if selected {
            self.messageLayout.setSelectMode(selected, message: message)
            self.msgSelectedLayout.isHidden = false
            if !showInput {
                self.msgSelectedLayout.snp.updateConstraints { [weak self] make in
                    guard let sf = self else {
                        return
                    }
                    make.height.equalTo(sf.msgSelectedLayout.getLayoutHeight())
                }
            }
        } else {
            self.messageLayout.setSelectMode(selected)
            self.msgSelectedLayout.isHidden = true
            if !showInput {
                self.msgSelectedLayout.snp.updateConstraints { make in
                    make.height.equalTo(0)
                }
            }
        }
    }

    /// 删除多选视图选中的消息
    public func deleteSelectedMessages() {
        let messages = self.messageLayout.getSelectMessages()
        if messages.count > 0 && session != nil {
            IMCoreManager.shared.messageModule
                .deleteMessages(session!.id, Array(messages), true)
                .compose(RxTransformer.shared.io2Main())
                .subscribe(
                    onError: { error in
                        DDLogError("deleteSelectedMessages \(error)")
                    },
                    onCompleted: {
                        DDLogInfo("deleteSelectedMessages success ")
                    }
                ).disposed(by: self.disposeBag)
        }
    }

    /// 设置已读消息
    public func readMessage(_ message: Message) {
        IMCoreManager.shared.messageModule
            .sendMessage(
                message.sessionId, MsgType.Read.rawValue, nil, nil, nil, message.msgId, nil)
    }

    /// 弹出消息操作面板弹窗
    public func popupMessageOperatorPanel(_ view: UIView, _ message: Message) {
        guard let session = self.session else {
            return
        }
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let atFrame = view.convert(view.bounds, to: nil)
        let operators = IMUIManager.shared.getMessageOperators(message, session)
        let rowCount = 5
        let popupWidth = min(operators.count * 60, 300)
        let popupHeight =
            ((operators.count / rowCount) + (operators.count % rowCount == 0 ? 0 : 1)) * 60
        var y = 0
        if atFrame.origin.y <= 300
            && (atFrame.origin.y + atFrame.size.height) >= (screenHeight - 300)
        {
            y = (Int(screenHeight) - popupHeight) / 2
        } else if atFrame.origin.y > 300 {
            y = Int(atFrame.origin.y) - popupHeight
        } else {
            y = Int(atFrame.origin.y) + Int(atFrame.size.height)
        }
        let frame = CGRect(
            x: (Int(screenWidth) - popupWidth) / 2, y: y, width: popupWidth, height: popupHeight)
        let popupView = IMMessageOperatorPopupView()
        self.view.addSubview(popupView)
        popupView.show(frame, rowCount, operators, self, message)
    }
    
    public func dismissMessageOperatorPanel() {
        self.view.subviews.forEach { v in
            if v is IMMessageOperatorPopupView {
                v.removeFromSuperview()
            }
        }
    }
    

    /// show loading
    public func showSenderLoading(text: String) {
        if Thread.current.isMainThread {
            self.showLoading(text: text)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.showLoading(text: text)
            }
        }
    }

    /// dismiss Loading
    public func dismissSenderLoading() {
        self.dismissLoading()
    }

    /// show toast
    public func showSenderToast(_ text: String) {
        self.showToast(text)
    }

    /// show error
    public func showSenderError(_ err: Error) {
        self.showError(err)
    }

    /// show message
    public func showSenderMessage(text: String, success: Bool) {
        if Thread.current.isMainThread {
            self.showToast(text, success)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.showToast(text, success)
            }
        }
    }

    /// 发送消息到session forwardType 0单条转发, 1合并转发
    public func forwardMessageToSession(messages: [Message], forwardType: Int) {
        let orderMessages = messages.sorted { m1, m2 in
            return m1.cTime > m2.cTime
        }
        IMSessionChooseViewController.popup(
            vc: self, forwardType: forwardType, messages: orderMessages, sender: self)
    }

    /// 转发选定的消息 forwardType 0单条转发, 1合并转发
    public func forwardSelectedMessages(forwardType: Int) {
        let messages = self.messageLayout.getSelectMessages()
        let orderMessages = messages.sorted { m1, m2 in
            return m1.cTime > m2.cTime
        }
        if orderMessages.count > 0 && session != nil {
            IMSessionChooseViewController.popup(
                vc: self, forwardType: forwardType, messages: orderMessages, sender: self)
        }
    }

    ///  打开at会话成员控制器
    public func openAtViewController() {
        guard let session = self.session else {
            return
        }
        if session.type == SessionType.Single.rawValue {
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
    public func addAtUser(user: User, sessionMember: SessionMember?) {
        self.inputLayout.addAtSessionMember(user: user, sessionMember: sessionMember)
    }

    /// 回复消息
    public func replyMessage(msg: Message) {
        self.showReplyMessage(msg)
    }

    /// 关闭回复消息
    public func closeReplyMessage() {
        self.dismissReplyMessage()
    }

    /// 重编辑消息
    public func reeditMessage(_ message: Message) {
        self.inputLayout.setReeditMessage(message)
    }

    /// 同步获取用户信息
    public func syncGetSessionMemberInfo(_ userId: Int64) -> (User, SessionMember?)? {
        return self.memberMap[userId]
    }

    /// 同步获取用户信息 用于@人 存入草稿再取出
    public func syncGetSessionMemberUserIdByNickname(_ nickname: String) -> Int64? {
        for (_, v) in self.memberMap {
            if v.1?.noteName == nickname || v.0.nickname == nickname {
                return v.0.id
            }
        }
        return nil
    }

    /// 设置用户信息
    public func saveSessionMemberInfo(_ info: (User, SessionMember?)) {
        self.memberMap[info.0.id] = info
    }

    /// 异步获取用户信息
    public func asyncGetSessionMemberInfo(_ userId: Int64) -> Observable<(User, SessionMember?)> {
        return IMCoreManager.shared.userModule.queryUser(id: userId)
            .flatMap { [weak self] user in
                if let sessionId = self?.session?.id {
                    let sessionMember = IMCoreManager.shared.database.sessionMemberDao()
                        .findSessionMember(sessionId, user.id)
                    return Observable.just((user, sessionMember))
                } else {
                    return Observable.just((user, nil))
                }
            }
    }

    public func onSessionMemberAt(_ memberInfo: (User, SessionMember?)) {
        self.inputLayout.addAtSessionMember(user: memberInfo.0, sessionMember: memberInfo.1)
    }

    ///  预览消息
    public func previewMessage(_ msg: Message, _ position: Int, _ originView: UIView) {
        let intercepted = IMUIManager.shared.getMsgCellProvider(msg.type).onMsgContentClick(
            self, msg, self.session, originView)
        if !intercepted {
            self.onMsgClick(msg, position, originView)
        }
    }

}
