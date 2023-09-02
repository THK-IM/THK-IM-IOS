//
//  IMMessageLayout.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/2.
//

import UIKit
import RxSwift
import CocoaLumberjack

class IMMessageReverseLayout: UIView, UITableViewDataSource, UITableViewDelegate, MsgCellDelegate {
    
    var session: Session? = nil
    weak var sender: IMMsgSender? = nil
    weak var previewer : IMMsgPreviewer? = nil
    
    private var messageTableView = UITableView()
    private let disposeBag = DisposeBag()
    private let loadCount = 20
    private var messages: Array<Message> = Array()
    private var isLoading = false
    private var isLoadAble = false
    private var lastMessageTime: Int64 = 0
    private let timeLineMsgType = 9999
    private let timeLineInterval = 5 * 60 * 1000
    private let lock = NSLock()
    
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
            (cell as! BaseMsgCell).contentView.transform = CGAffineTransformMakeScale (1,-1)
        }
        (cell as! BaseMsgCell).setMessage(self.messages, indexPath.row)
        (cell as! BaseMsgCell).selectedBackgroundView = UIView()
        (cell as! BaseMsgCell).multipleSelectionBackgroundView = UIView(frame: cell!.bounds)
        (cell as! BaseMsgCell).multipleSelectionBackgroundView?.backgroundColor = UIColor.clear
        print("cellForRowAt \(indexPath)")
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
        let height = provider.cellHeight(msg, self.session!.type)
        return height
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = self.messageTableView.contentSize.height - self.messageTableView.contentOffset.y - self.messageTableView.frame.height
        
        print("scrollViewDidScroll \(self.messageTableView.contentSize.height), \(self.messageTableView.contentOffset.y) \(offsetY) \(isLoadAble)")
        if (offsetY < -20  && !self.messageTableView.isDragging )  {
            if (!isLoadAble) {
                isLoadAble = true
            }
        } else if (offsetY < 0 ) { // 回弹时再去load
            if isLoadAble {
                self.loadMessages()
                isLoadAble = false
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
            latestMsgTime = self.messages[self.messages.count-1].cTime
        }
        if (self.session != nil) {
            IMCoreManager.shared.getMessageModule()
                .queryLocalMessages((self.session?.id)!, latestMsgTime, self.loadCount)
                .compose(DefaultRxTransformer.io2Main())
                .subscribe(onNext: { [weak self] value in
                    guard let sf = self else { return }
                    sf.addMessage(value)
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
        self.messageTableView.transform = CGAffineTransformMakeScale (1,-1)
        self.messageTableView.rx.tapGesture(configuration: { gestureRecognizer, delegate in
            delegate.beginPolicy = .custom { [weak self] gestureRecognizer in
                return !(self?.messageTableView.isEditing ?? false)
            }
            delegate.otherFailureRequirementPolicy = .custom { gestureRecognizer, otherGestureRecognizer in
                return otherGestureRecognizer is UILongPressGestureRecognizer
            }
        }).when(.ended)
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
            newMessages.append(m)
            let msg = addTimelineMessage(m)
            if (msg != nil) {
                newMessages.append(msg!)
            }
        }
        return newMessages
    }
    
    func addMessage(_ messages: Array<Message>) {
        lock.lock()
        defer {lock.unlock()}
        if (messages.isEmpty) {
            return
        }
        let tableView = self.messageTableView
        let oldCount = self.messages.count
        let messagesWithTimeLine = self.appendMessages(messages)
        self.messages.insert(contentsOf: messagesWithTimeLine, at: oldCount)
        let newCount = self.messages.count
        var paths = Array<IndexPath>()
        for i in (oldCount ..< newCount) {
            paths.append(IndexPath.init(row: i, section: 0))
        }
        UIView.setAnimationsEnabled(false)
        tableView.insertRows(at: paths.reversed(), with: .none)
        UIView.setAnimationsEnabled(true)
    }
    
    func insertMessage(_ message: Message) {
        lock.lock()
        defer {lock.unlock()}
        let tableView = self.messageTableView
        let pos = findPosition(message)
        if (pos == -1) {
            // 新消息，找到合适的位置，插入
            let insertPos = findInsertPosition(message)
            if (insertPos < self.messages.count - 1){
                lastMessageTime = self.messages[insertPos+1].cTime
            } else {
                lastMessageTime = 0
            }
            let timelineMsg = addTimelineMessage(message)
            if (timelineMsg != nil) {
                self.messages.insert(message, at: insertPos)
                self.messages.insert(timelineMsg!, at: insertPos  + 1)
                tableView.insertRows(at: [IndexPath.init(row: insertPos, section: 0),
                                          IndexPath.init(row: insertPos + 1, section: 0)],
                                     with: .top)
            } else {
                self.messages.insert(message, at: insertPos)
                tableView.insertRows(at: [IndexPath.init(row: insertPos, section: 0)], with: .top)
            }
        } else {
            // 老消息，替换reload
            self.messages[pos] = message
            tableView.reloadRows(at: [IndexPath.init(row: pos, section: 0)], with: .none)
        }
    }
    
    func deleteMessage(_ message: Message) {
        lock.lock()
        defer {lock.unlock()}
        let tableView = self.messageTableView
        let pos = findPosition(message)
        if (pos != -1) {
            self.messages.remove(at: pos)
            tableView.deleteRows(at: [IndexPath.init(row: pos, section: 0)], with: .none)
        }
    }
    
    private func findPosition(_ message: Message) -> Int {
        var pos = 0
        for msg in self.messages {
            if (msg.id == message.id) {
                return pos
            }
            pos += 1
        }
        return -1
    }
    
    private func findInsertPosition(_ message: Message) -> Int {
        var pos = 0
        for msg in self.messages {
            if (message.cTime > msg.cTime) {
                return pos
            }
            pos += 1
        }
        return pos
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
    
    private var lastResize = 0.0
    func layoutResize(_ height: CGFloat) {
//        var offsetY = (height - lastResize) < 0 ? 0 : (height - lastResize)
//        offsetY = self.messageTableView.contentOffset.y - offsetY
//        self.messageTableView.setContentOffset(CGPoint(x: 0, y: offsetY), animated: false)
//        lastResize = height
    }
}
