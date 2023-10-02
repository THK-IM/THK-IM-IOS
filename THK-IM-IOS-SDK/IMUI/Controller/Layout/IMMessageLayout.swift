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
    
    var session: Session? = nil
    var messages: Array<Message> = Array()
    weak var sender: IMMsgSender? = nil
    weak var previewer : IMMsgPreviewer? = nil
    
    private var messageTableView = UITableView()
    private let disposeBag = DisposeBag()
    private let loadCount = 20
    private var isLoading = false
    private var isLoadAble = false
    private var lastMessageTime: Int64 = 0
    private let timeLineMsgType = 9999
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
        let message = self.messages[indexPath.row]
        return message.type != 9999
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let msg = self.messages[indexPath.row]
        let provider = IMUIManager.shared.getMsgCellProvider(msg.type)
        let size = provider.viewSize(msg)
        return size.height + 20
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = self.messageTableView.contentOffset.y
        if (offsetY < -20) {
            if (isLoadAble && !self.messageTableView.isDragging ) {
                self.loadMessages()
                isLoadAble = false
            }
        } else if (offsetY >= 0 ) { // 回弹时再去load
            if (!isLoadAble) {
                isLoadAble = true
            }
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
        var latestMsgTime: Int64 = 0
        if (self.messages.count == 0) {
            latestMsgTime = IMCoreManager.shared.severTime
        } else {
            latestMsgTime = self.messages[0].cTime
        }
        if (self.session != nil) {
            IMCoreManager.shared.getMessageModule()
                .queryLocalMessages((self.session?.id)!, latestMsgTime, self.loadCount)
                .compose(RxTransformer.shared.io2Main())
                .subscribe(onNext: { [weak self] value in
                    guard let sf = self else { return }
                    sf.addMessage(value.reversed())
                    if (value.count >= sf.loadCount) {
                        sf.isLoading = false
                    }
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
        let message = Message(
            id: 0, sessionId: self.session?.id ?? 0, fromUId: 0, msgId: 0, type: 0, content: "", sendStatus: 0,
            operateStatus: 0, referMsgId: nil, atUsers: nil, data: "", cTime: 0, mTime: 0
        )
        message.cTime = cTime
        message.type = 9999
        return message
    }
    
    private func addTimelineMessage(_ message: Message) -> Message? {
        var msg : Message? = nil
        if (abs(message.cTime - lastMessageTime) > timeLineInterval) {
            msg = newTimelineMessage(message.cTime)
        }
        lastMessageTime = message.cTime
        return msg
    }
    
    func appendMessages(_ messages: Array<Message>) -> Array<Message> {
        if (messages.isEmpty) {
            return []
        }
        var newMessages = Array<Message>()
        for m in messages {
            let msg = addTimelineMessage(m)
            if (msg != nil) {
                newMessages.append(msg!)
            }
            newMessages.append(m)
        }
        return newMessages
    }
    
    func addMessage(_ messages: Array<Message>) {
        if (messages.isEmpty) {
            return
        }
        let tableView = self.messageTableView
        let messagesWithTimeLine = self.appendMessages(messages)
        self.messages.insert(contentsOf: messagesWithTimeLine, at: 0)
        var paths = Array<IndexPath>()
        for i in (0 ..< messagesWithTimeLine.count) {
            paths.append(IndexPath.init(row: i, section: 0))
        }
        UIView.setAnimationsEnabled(false)
        tableView.insertRows(at: paths, with: .none) 
        tableView.scrollToRow(
            at: IndexPath(row: messagesWithTimeLine.count-1, section: 0),
            at: .none,
            animated: false
        )
        UIView.setAnimationsEnabled(true)
    }
    
    func insertMessages(_ messages: Array<Message>) {
        let count = messages.count
        if count == 1 {
            self.insertMessage(messages[0])
        } else if messages.count > 1 {
            let messagesWithTimeLine = self.appendMessages(messages)
            let firstPos = findInsertPosition(messagesWithTimeLine[0])
            self.messages.insert(contentsOf: messagesWithTimeLine, at: firstPos)
            var paths = Array<IndexPath>()
            for i in (firstPos ..< firstPos + messagesWithTimeLine.count) {
                paths.append(IndexPath.init(row: i, section: 0))
            }
            UIView.setAnimationsEnabled(false)
            self.messageTableView.insertRows(at: paths, with: .none)
            UIView.setAnimationsEnabled(true)
        }
    }
    
    func insertMessage(_ message: Message) {
        let tableView = self.messageTableView
        let pos = findPosition(message)
        if (pos != -1) {
            // 老消息，替换reload
            self.messages[pos] = message
            tableView.reloadRows(at: [IndexPath.init(row: pos, section: 0)], with: .none)
            return
        }
        let insertPos = findInsertPosition(message)
        if (insertPos > 1){
            lastMessageTime = self.messages[insertPos-1].cTime
        } else {
            lastMessageTime = 0
        }
        
        UIView.setAnimationsEnabled(false)
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
    
//    func updateMessage(_ message: Message) {
//        let tableView = self.messageTableView
//        let pos = findPosition(message)
//        if (pos != -1) {
//            // 老消息，替换reload
//            self.messages[pos] = message
//            tableView.reloadRows(at: [IndexPath.init(row: pos, section: 0)], with: .none)
//        }
//    }
    
    func deleteMessage(_ message: Message) {
        let tableView = self.messageTableView
        let pos = findPosition(message)
        UIView.setAnimationsEnabled(false)
        if (pos != -1) {
            self.messages.remove(at: pos)
            tableView.deleteRows(at: [IndexPath.init(row: pos, section: 0)], with: .none)
        }
        UIView.setAnimationsEnabled(true)
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
    
    
    func onMsgCellClick(message: Message, position: Int, view: UIView) {
        self.previewer?.previewMessage(message, position, view)
    }
    
    func onMsgCellLongClick(message: Message, position: Int, view: UIView) {
        self.sender?.showMsgSelectedLayout()
    }
    
    func onMsgResendClick(message: Message) {
        self.sender?.resendMessage(message)
    }
    
    func setMessageEditing(_ editing: Bool) {
        self.messageTableView.isEditing = editing
    }
    
    func getContentHeight() -> CGFloat {
        return self.messageTableView.contentSize.height
    }
    
    func layoutResize(_ height: CGFloat) {
        let offsetY = self.messageTableView.contentOffset.y + (height-lastResize)
        self.messageTableView.setContentOffset(CGPoint(x: 0, y: offsetY), animated: false)
        lastResize = height
    }
}
