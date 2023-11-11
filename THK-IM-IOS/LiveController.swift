//
//  LiveController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/2.
//

import UIKit
import WebRTC
import SnapKit
import RxSwift
import CocoaLumberjack

class LiveController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, RoomDelegate {
    
    
    private let key = "UIRtcMsgCell"
    private var messages = [String]()
    
    private var containerView = UIView()
    private var lastResize = 0.0
    private let disposeBag = DisposeBag()
    private var room: Room? = nil
    
    lazy var messagesView: UITableView = {
        let v = UITableView()
        v.dataSource = self
        v.delegate = self
        v.separatorStyle = .none
        v.register(UIRtcMsgCell.self, forCellReuseIdentifier: key)
        return v
    }()
    
    lazy var participantsLayout: UIScrollView = {
        let v = UIScrollView()
        v.showsVerticalScrollIndicator = false
        v.showsHorizontalScrollIndicator = false
        v.autoresizingMask = .flexibleWidth
        return v
    }()
    
    lazy var msgSendLayout: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.init(hex: "eeeeee")
        return v
    }()
    
    lazy var msgEditView: UITextView = {
        let textView = UITextView()
        textView.delegate = self
        textView.isScrollEnabled = true
        textView.font = UIFont.systemFont(ofSize: 14.0)
        textView.returnKeyType = .send
        textView.keyboardType = .default
        textView.showsVerticalScrollIndicator = false
        textView.showsHorizontalScrollIndicator = false
        textView.contentInset = UIEdgeInsets(top: 20, left: 4, bottom: 20, right: 4)
        return textView
    }()
    
    lazy var senderBtn: UIButton = {
        let button = UIButton.init(type: .roundedRect)
        button.setTitle("send", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.backgroundColor = .blue
        button.layer.cornerRadius = 6
        button.layer.masksToBounds = true
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        registerKeyboardEvent()
        
        self.view.backgroundColor = UIColor.init(hex: "f5f5f5")
        self.view.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(getNavTop()+getNavHeight())
            make.bottom.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        containerView.clipsToBounds = true
        
        self.containerView.addSubview(msgSendLayout)
        self.containerView.addSubview(messagesView)
        self.containerView.addSubview(participantsLayout)
        
        msgSendLayout.snp.makeConstraints { make in
            make.height.equalTo(60)
            make.bottom.equalToSuperview().offset(-UIApplication.shared.windows[0].safeAreaInsets.bottom)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        
        participantsLayout.snp.makeConstraints { [weak self] make in
            guard let sf = self else {
                return
            }
            make.top.equalToSuperview()
            make.bottom.equalTo(sf.msgSendLayout.snp.top)
            make.right.equalToSuperview()
            make.width.equalTo(160)
        }
        messagesView.snp.makeConstraints {  [weak self] make in
            guard let sf = self else {
                return
            }
            make.top.equalToSuperview()
            make.bottom.equalTo(sf.msgSendLayout.snp.top)
            make.left.equalToSuperview()
            make.right.equalTo(sf.participantsLayout.snp.left)
        }
        messagesView.backgroundColor = UIColor.init(hex: "f5f5f5")
        
        containerView.rx.tapGesture(configuration: { gestureRecognizer, delegate in
            delegate.otherFailureRequirementPolicy = .custom { gestureRecognizer, otherGestureRecognizer in
                return otherGestureRecognizer is UILongPressGestureRecognizer
            }
        })
        .when(.ended)
        .subscribe(onNext: { [weak self] _ in
            self?.msgEditView.endEditing(true)
        })
        .disposed(by: disposeBag)
        
        msgSendLayout.addSubview(msgEditView)
        msgEditView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        msgSendLayout.addSubview(senderBtn)
        senderBtn.snp.makeConstraints {make in
            make.width.equalTo(40)
            make.height.equalTo(30)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-20)
        }
        senderBtn.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let sf = self else {
                    return
                }
                sf.send()
            })
            .disposed(by: self.disposeBag)
        senderBtn.isHidden = true
        UIApplication.shared.isIdleTimerDisabled = true
        
        joinRoom()
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
        self.moveUpAlwaysShowView(true, keyboardHeight, duration)
    }
    
    @objc func keyboardWillDisappear(note: NSNotification){
        let animation = note.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey]
        let duration: Double = (animation as AnyObject).doubleValue
        self.moveUpAlwaysShowView(false, 0, duration)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: key, for: indexPath) as! UIRtcMsgCell
        cell.setMessage(messages[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let height = cellHeight(messages[indexPath.row])
        return height
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text.count > 0 {
            senderBtn.isHidden = false
        } else {
            senderBtn.isHidden = true
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // 判断是否是发送按钮被点击（根据换行符判断）
        if text == "\n" {
            self.send()
            return false
        }
        return true
    }
    
    private func send() {
//        let count = self.messages.count
//        self.messages.append(self.msgEditView.text)
//        self.messagesView.insertRows(at: [IndexPath.init(row: count, section: 0)], with: .none)
        guard let room = self.room else {
            return
        }
        if self.msgEditView.text.count <= 0 {
            return
        }
        
        let success = room.sendMessage(self.msgEditView.text)
        if success {
            self.msgEditView.text = nil
        }
    }
    
    private func getNavHeight() -> CGFloat {
        var navHeight: CGFloat = 0
        if (self.navigationController != nil) {
            navHeight = self.navigationController!.navigationBar.frame.size.height
        }
        return navHeight
    }
    
    private func getNavTop() -> CGFloat {
        var top: CGFloat = 0
        if (self.navigationController != nil) {
            top = self.navigationController!.navigationBar.frame.origin.y
        }
        return top
    }
    
    func moveUpAlwaysShowView(_ isKeyboardShow: Bool, _ height: CGFloat, _ duration: Double) {
        self.msgSendLayout.snp.updateConstraints { make in
            if (height == 0) {
                make.bottom.equalToSuperview().offset(-(UIApplication.shared.windows[0].safeAreaInsets.bottom))
            } else {
                make.bottom.equalToSuperview().offset(-(height))
            }
        }
        UIView.animate(withDuration: duration, animations: { [weak self] in
            guard let sf = self else {
                return
            }
            if height > 0 {
                sf.layoutResize(height-UIApplication.shared.windows[0].safeAreaInsets.bottom)
            } else {
                sf.layoutResize(height)
            }
            sf.containerView.layoutIfNeeded()
        }, completion: { (finished) in
            
        })
    }
    
    func layoutResize(_ height: CGFloat) {
        let offsetY = self.messagesView.contentOffset.y + (height-lastResize)
        self.messagesView.setContentOffset(CGPoint(x: 0, y: offsetY), animated: false)
        self.participantsLayout.setContentOffset(CGPoint(x: 0, y: offsetY), animated: false)
        lastResize = height
    }
    
    func cellHeight(_ message: String) -> CGFloat {
        let width = self.messagesView.frame.width - 8
        let height = self.heightWithString(message, UIFont.systemFont(ofSize: 16.0), width)
        return height + 16
    }
    
    
    private func heightWithString(_ text: String, _ font: UIFont, _ maxWidth: CGFloat) -> CGFloat {
        var height: CGFloat = 0
        if text.isEmpty {
            height = 0
        } else {
            var attribute = [NSAttributedString.Key: Any]()
            attribute[.font] = font
            let retSize = (text as NSString).boundingRect(
                with: CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attribute,
                context: nil
            ).size
            height = retSize.height
        }
        return height
    }
    
    func joinRoom() {
        LiveManager.shared.joinRoom(roomId: "1", role: Role.Broadcaster, token: "xxxxxx")
            .compose(RxTransformer.shared.io2Main())
            .subscribe(onNext: { [weak self] room in
                guard let sf = self else {
                    return
                }
                sf.initRoom(room: room)
            }).disposed(by: self.disposeBag)
    }
    
    func initRoom(room: Room) {
        self.room = room
        room.registerObserver(self)
        let participants = room.getAllParticipants()
        for p in participants {
            self.join(p)
        }
    }
    
    func join(_ p: BaseParticipant) {
        DDLogInfo("join: \(p.uId), \(p.roomId), \(self.participantsLayout.subviews.count)")
        let count = self.participantsLayout.subviews.count
        let v = ParticipantView(frame: CGRect(x:0, y: CGFloat(count) * 240.0, width: self.participantsLayout.frame.width, height: 240))
        self.participantsLayout.addSubview(v)
        self.participantsLayout.contentSize = CGSize(width: self.participantsLayout.frame.width, height: CGFloat((count+1)) * 240.0)
        v.setParticipant(p: p)
    }
    
    func leave(_ p: BaseParticipant) {
        for v in self.participantsLayout.subviews {
            let participantView = v as! ParticipantView
            if participantView.p == p {
                v.removeFromSuperview()
                break
            }
        }
        
        var i = 0
        for v in self.participantsLayout.subviews {
            v.frame = CGRect(x:0, y: CGFloat(i) * 240.0, width: self.participantsLayout.frame.width, height: 240)
            i += 1
        }
        self.participantsLayout.contentSize = CGSize(width: self.participantsLayout.frame.width, height: CGFloat(i) * 240.0)
    }
    
    func onTextMsgReceived(uId: String, text: String) {
        let content = "user-\(uId): \(text)"
        let count = self.messages.count
        self.messages.append(content)
        self.messagesView.insertRows(at: [IndexPath.init(row: count, section: 0)], with: .none)
    }
    
    func onBufferMsgReceived(data: Data) {
        
    }
    
    
    deinit {
        DDLogInfo("LiveController deinit")
        LiveManager.shared.destroyRoom()
    }
}
