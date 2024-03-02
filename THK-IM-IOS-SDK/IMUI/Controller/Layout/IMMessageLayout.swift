//
//  IMMessageLayout.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/2.
//

import UIKit
import RxSwift
import CocoaLumberjack

class IMMessageLayout: UIView, UITableViewDataSource, UITableViewDelegate, IMMsgCellOperator {
    
    var mode: Int = 0 // 0 正常模式，1预览消息记录模式
    var session: Session? = nil
    var messages: Array<Message> = Array()
    private var selectedMessages: Set<Message> = Set()
    weak var sender: IMMsgSender? = nil
    weak var previewer : IMMsgPreviewer? = nil
    
    private var messageTableView = UITableView()
    private let disposeBag = DisposeBag()
    private let loadCount = 20
    private var isLoading = false
    private var isLoadAble = false
    private var lastTimelineMsgCTime: Int64 = 0
    private let timeLineInterval = 5 * 60 * 1000
    private let lock = NSLock()
    private var lastResize = 0.0
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadMessageView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let msg = self.messages[indexPath.row]
        let provider = IMUIManager.shared.getMsgCellProvider(msg.type)
        let viewType = provider.viewType(msg)
        let identifier = provider.identifier(viewType)
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier)
        if cell == nil {
            cell = provider.viewCell(viewType, (self.session?.type)!)
        }
        (cell as! BaseMsgCell).setMessage(indexPath.row, self.messages, self.session!, self)
        (cell as! BaseMsgCell).selectedBackgroundView = UIView()
        (cell as! BaseMsgCell).isSelected = selectedMessages.contains(msg)
        (cell as! BaseMsgCell).multipleSelectionBackgroundView = UIView(frame: cell!.bounds)
        (cell as! BaseMsgCell).multipleSelectionBackgroundView?.backgroundColor = UIColor.clear
        return cell!
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let messageCellView = cell as! BaseMsgCell
        messageCellView.delegate = self
        messageCellView.appear()
    }
    
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let sessionCell = cell as! BaseMsgCell
        sessionCell.disappear()
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let msg = self.messages[indexPath.row]
        let provider = IMUIManager.shared.getMsgCellProvider(msg.type)
        return provider.canSelected()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        DDLogInfo("didSelectRowAt \(indexPath.row)")
        let message = self.messages[indexPath.row]
        self.selectedMessages.insert(message)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        DDLogInfo("didDeselectRowAt \(indexPath.row)")
        let message = self.messages[indexPath.row]
        self.selectedMessages.remove(message)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let msg = self.messages[indexPath.row]
        return self.msgCellHeight(msg)
    }
    
    private func msgCellHeight(_ msg: Message) -> CGFloat {
        let provider = IMUIManager.shared.getMsgCellProvider(msg.type)
        let size = provider.viewSize(msg, self.session)
        var addHeight = provider.msgTopForSession(msg, self.session)
        if let referMsg = msg.referMsg  {
            addHeight += IMUIManager.shared.getMsgCellProvider(referMsg.type).replyMsgViewSize(referMsg, self.session).height
            addHeight += 30 // 补齐回复人视图高度
        }
        return size.height + addHeight
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (session?.type == SessionType.MsgRecord.rawValue) {
            return
        }
        let offsetY = self.messageTableView.contentOffset.y
        if (offsetY < 200) {
            if isLoadAble {
                if (!self.messageTableView.isDragging) {
                    self.loadMessages()
                    isLoadAble = false
                }
            }
        } else {
            isLoadAble = true
        }
    }
    
    func scrollToBottom(_ delay: CGFloat = 0.1) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if (self.messages.count > 0) {
                let rows = self.messageTableView.numberOfRows(inSection: 0)
                if (rows > 0) {
                    let indexPath = IndexPath(row: rows - 1, section: 0)
                    self.messageTableView.scrollToRow(
                        at: indexPath,
                        at: UITableView.ScrollPosition.bottom,
                        animated: true
                    )
                }
            }
        }
    }
    
    func loadMessages() {
        if (isLoading) {
            return
        }
        isLoading = true
        var endTime: Int64 = 0
        var excludeIds = [Int64]()
        if let firstMsg = self.messages.first(where: { msg in
            return msg.type != MsgType.TimeLine.rawValue
        }) {
            excludeIds.append(firstMsg.msgId)
            endTime = firstMsg.cTime
        } else {
            endTime = IMCoreManager.shared.severTime
        }
        if (self.session != nil) {
            IMCoreManager.shared.messageModule
                .queryLocalMessages((self.session?.id)!, 0, endTime, self.loadCount, excludeIds)
                .compose(RxTransformer.shared.io2Main())
                .subscribe(onNext: { [weak self] value in
                    self?.addMessages(value)
                }, onCompleted: { [weak self] in
                    self?.isLoading = false
                }).disposed(by: self.disposeBag)
        }
    }
    
    private func loadMessageView() {
        self.addSubview(self.messageTableView)
        self.messageTableView.backgroundColor = UIColor.clear
        self.messageTableView.dataSource = self
        self.messageTableView.delegate = self
        self.messageTableView.allowsSelection = true
        self.messageTableView.allowsMultipleSelection = true
        self.messageTableView.allowsMultipleSelectionDuringEditing = true
        self.messageTableView.snp.makeConstraints { (make) -> Void in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        self.messageTableView.separatorStyle = .none
        
        self.messageTableView.rx.tapGesture(configuration: { gestureRecognizer, delegate in
            delegate.beginPolicy = .custom { [weak self] gestureRecognizer in
                return !(self?.messageTableView.isEditing ?? false)
            }
            delegate.otherFailureRequirementPolicy = .custom { gestureRecognizer, otherGestureRecognizer in
                if (gestureRecognizer.cancelsTouchesInView) {
                    return true
                }
                return otherGestureRecognizer is UILongPressGestureRecognizer
            }
        })
        .when(.ended)
        .subscribe(onNext: { [weak self]  _ in
            self?.sender?.closeBottomPanel()
        })
        .disposed(by: disposeBag)
    }
    
    private func newTimelineMessage(_ cTime: Int64) -> Message {
        let id = IMCoreManager.shared.messageModule.generateNewMsgId()
        let message = Message(
            id: id, sessionId: self.session?.id ?? 0, fromUId: 0, msgId: 0, type: MsgType.TimeLine.rawValue,
            content: "", data: "", sendStatus: 0, operateStatus: 0, referMsgId: nil, extData: nil, atUsers: nil,
            cTime: cTime, mTime: 0
        )
        lastTimelineMsgCTime = cTime
        return message
    }
    
    private func addTimelineMessage(_ message: Message) -> Message? {
        var timeLineMsg : Message? = nil
        if (abs(message.cTime - lastTimelineMsgCTime) > timeLineInterval) {
            timeLineMsg = newTimelineMessage(message.cTime)
        }
        return timeLineMsg
    }
    
    func appendTimeLineMessages(_ messages: Array<Message>) -> Array<Message> {
        if (messages.isEmpty) {
            return []
        }
        if let firstMsg = self.messages.first {
            lastTimelineMsgCTime = firstMsg.cTime
        }
        var newMessages = Array<Message>()
        for m in messages {
            newMessages.append(m)
            let msg = addTimelineMessage(m)
            if (msg != nil) {
                newMessages.append(msg!)
            }
        }
        if let lastMsg = newMessages.last {
            if lastMsg.type != MsgType.TimeLine.rawValue {
                let timeLineMsg = newTimelineMessage(lastMsg.cTime)
                newMessages.append(timeLineMsg)
            }
        }
        return newMessages
    }
    
    func addMessages(_ messages: Array<Message>) {
        if (messages.isEmpty) {
            return
        }
        let messagesWithTimeLine = self.appendTimeLineMessages(messages)
        UIView.setAnimationsEnabled(false)
        var indexPaths = [IndexPath]()
        for i in (0 ..< messagesWithTimeLine.count) {
            self.messages.insert(messagesWithTimeLine[i], at: 0)
            indexPaths.append(IndexPath(row: i, section: 0))
        }
        self.messageTableView.insertRows(at: indexPaths, with: .none)
        let scrollTo = min(messagesWithTimeLine.count-1, self.messages.count-1)
        self.messageTableView.scrollToRow(
            at: IndexPath(row: scrollTo, section: 0),
            at: .top,
            animated: false
        )
        UIView.setAnimationsEnabled(true)
    }
    
    func insertMessages(_ messages: Array<Message>) {
        var realInsertMsgs = Array<Message>()
        for m in messages {
            let pos = self.findPosition(m)
            if (pos == -1) {
                realInsertMsgs.append(m)
            } else {
                if (self.messages[pos].sendStatus != m.sendStatus) {
                    self.messages[pos].sendStatus = m.sendStatus
                    self.messages[pos].msgId = m.msgId
                    self.messageTableView.reloadRows(at: [IndexPath.init(row: pos, section: 0)], with: .none)
                }
            }
        }
        for m in realInsertMsgs {
            self.insertMessage(m)
        }
    }
    
    func insertMessage(_ message: Message) {
        DDLogDebug("insertMessage \(message)")
        let tableView = self.messageTableView
        let pos = findPosition(message)
        if (pos != -1) {
            // 老消息，替换reload
            self.messages[pos] = message
            tableView.reloadRows(at: [IndexPath.init(row: pos, section: 0)], with: .none)
            return
        }
        let insertPos = findInsertPosition(message)
        UIView.setAnimationsEnabled(false)
        if insertPos > 0 {
            lastTimelineMsgCTime = self.messages[insertPos-1].cTime
        }
        let timelineMsg = addTimelineMessage(message)
        if (timelineMsg != nil) {
            self.messages.insert(timelineMsg!, at: insertPos)
            self.messages.insert(message, at: insertPos  + 1)
            tableView.insertRows(at: [IndexPath.init(row: insertPos, section: 0),
                                      IndexPath.init(row: insertPos + 1, section: 0)],
                                 with: .none)
        } else {
            self.messages.insert(message, at: insertPos)
            tableView.insertRows(at: [IndexPath.init(row: insertPos, section: 0)], with: .none)
        }
        UIView.setAnimationsEnabled(true)
        self.scrollToBottom(0.2)
    }
    
    func updateMessage(_ message: Message) {
        let tableView = self.messageTableView
        let pos = findPosition(message)
        if (pos != -1) {
            // 老消息，替换reload
            self.messages[pos] = message
            tableView.reloadRows(at: [IndexPath.init(row: pos, section: 0)], with: .none)
        }
    }
    
    func deleteMessage(_ message: Message) {
        var deletePaths = [IndexPath]()
        var positions = [Int]()
        let pos = findPosition(message)
        if (pos < 0) {
            return
        }
        positions.append(pos)
        if (pos - 1 > 0 && self.messages[pos - 1].type == MsgType.TimeLine.rawValue) {
            positions.append(pos-1)
        }
        for pos in positions.sorted().reversed() {
            self.messages.remove(at: pos)
            deletePaths.append(IndexPath.init(row: pos, section: 0))
        }
        self.messageTableView.deleteRows(at: deletePaths, with: .none)
    }
    
    func deleteMessages(_ messages: Array<Message>) {
        var deletePaths = [IndexPath]()
        var positions = [Int]()
        for msg in messages {
            let pos = findPosition(msg)
            if (pos < 0) {
                continue
            }
            positions.append(pos)
            if (pos - 1 > 0 && self.messages[pos - 1].type == MsgType.TimeLine.rawValue) {
                positions.append(pos-1)
            }
        }
        for pos in positions.sorted().reversed() {
            self.messages.remove(at: pos)
            deletePaths.append(IndexPath.init(row: pos, section: 0))
        }
        self.messageTableView.deleteRows(at: deletePaths, with: .none)
    }
    
    private func findPosition(_ message: Message) -> Int {
        let count = self.messages.count
        for i in 0 ..< count {
            if (message.id == self.messages[count-1-i].id) {
                return count-1-i
            }
        }
        return -1
    }
    
    private func findInsertPosition(_ message: Message) -> Int {
        let count = self.messages.count
        for i in 0 ..< count {
            if (message.cTime >= self.messages[count-1-i].cTime) {
                return count-i
            }
        }
        return 0
    }
    
    func onMsgReferContentClick(message: Message, view: UIView) {
        if let row = self.messages.firstIndex(of: message) {
            self.scrollToRow(row)
        } else {
            // 尝试从db中获取
            if let lastMsg = self.messages.last {
                let startTime = message.cTime
                let endTime = lastMsg.cTime
                IMCoreManager.shared.messageModule.queryLocalMessages(message.sessionId, startTime, endTime, Int.max, [lastMsg.msgId])
                    .compose(RxTransformer.shared.io2Main())
                    .subscribe(onNext: { [weak self] messages in
                        guard let sf = self else {
                            return
                        }
                        sf.addMessages(messages)
                        if let row = sf.messages.firstIndex(of: message) {
                            sf.scrollToRow(row)
                        }
                    }).disposed(by: self.disposeBag)
            }
        }
    }
    
    private func scrollToRow(_ row: Int) {
        self.messageTableView.scrollToRow(at: IndexPath(row: row, section: 0), at: .top, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { [weak self] in
            (self?.messageTableView.cellForRow(at: IndexPath(row: row, section: 0)) as? BaseMsgCell)?.highlightFlashing(6)
        })
    }
    
    func onMsgCellClick(message: Message, position: Int, view: UIView) {
        self.previewer?.previewMessage(message, position, view)
    }
    
    func onMsgSenderClick(message: Message, position: Int, view: UIView) {
        IMCoreManager.shared.userModule.queryUser(id: message.fromUId)
            .compose(RxTransformer.shared.io2Main())
            .subscribe(onNext: { [weak self] user in
                guard let vc = self?.getViewController() else {
                    return 
                }
                IMUIManager.shared.pageRouter?.openUserPage(controller: vc, user: user)
            }).disposed(by: self.disposeBag)
    }
    
    func onMsgSenderLongClick(message: Message, position: Int, view: UIView) {
        guard let session = self.session else {
            return
        }
        if (session.type != SessionType.Group.rawValue &&
            session.type != SessionType.SuperGroup.rawValue) {
            return
        }
        IMCoreManager.shared.userModule.queryUser(id: message.fromUId)
            .compose(RxTransformer.shared.io2Main())
            .subscribe(onNext: { [weak self] user in
                self?.sender?.addAtUser(user: user, sessionMember: nil)
            }).disposed(by: self.disposeBag)
    }
    
    
    func onMsgCellLongClick(message: Message, position: Int, view: UIView) {
        self.sender?.popupMessageOperatorPanel(view, message)
    }
    
    func onMsgResendClick(message: Message) {
        self.sender?.resendMessage(message)
    }
    
    func readMessage(_ message: Message) {
        self.sender?.readMessage(message)
    }
    
    func setEditText(text: String) {
        _ = self.sender?.openKeyboard()
        self.sender?.addInputContent(text: text)
    }
    
    
    func getContentHeight() -> CGFloat {
        return self.messageTableView.contentSize.height
    }
    
    func layoutResize(_ height: CGFloat) {
        let offsetY = self.messageTableView.contentOffset.y + (height-lastResize)
        self.messageTableView.setContentOffset(CGPoint(x: 0, y: offsetY), animated: false)
        lastResize = height
    }
    
    func isSelectMode() -> Bool {
        return self.messageTableView.isEditing
    }
    
    func isItemSelected(message: Message) -> Bool {
        return self.selectedMessages.contains(message)
    }
    
    func onSelected(message: Message, selected: Bool) {
        if (selected) {
            self.selectedMessages.insert(message)
        } else {
            self.selectedMessages.remove(message)
        }
    }
    
    func setSelectMode(_ selected: Bool, message: Message? = nil) {
        if self.messageTableView.isEditing != selected {
            if (selected) {
                if (message != nil) {
                    self.selectedMessages.insert(message!)
                    let pos = self.findPosition(message!)
                    if (pos >= 0) {
                        self.messageTableView.cellForRow(at: IndexPath.init(row: pos, section: 0))?.isSelected = true
                    }
                }
            } else {
                self.selectedMessages.removeAll()
            }
            self.messageTableView.isEditing = selected
        }
    }
    
    func getSelectMessages() -> Set<Message> {
        return self.selectedMessages
    }
    
    private func getViewController() -> UIViewController? {
        for view in sequence(first: self.superview, next: { $0?.superview }) {
            if let responder = view?.next {
                if responder.isKind(of: UIViewController.self){
                    return responder as? UIViewController
                }
            }
        }
        return nil
    }
}
