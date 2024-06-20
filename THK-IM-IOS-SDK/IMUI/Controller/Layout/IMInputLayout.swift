//
//  TextInputLayout.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/4.
//

import UIKit
import CocoaLumberjack
import SnapKit
import RxSwift
import YbridOpus
import AVFoundation
import CoreAudio

public class IMInputLayout: UIView, UITextViewDelegate, TextViewBackwardDelegate {
    
    weak var sender: IMMsgSender? = nil {
        didSet {
            self.speakView.sender = sender
            self.replyView.sender = sender
        }
    }
    private static let maxTextInputHeight: CGFloat = 120.0
    private static let minTextInputHeight: CGFloat = 40.0
    private let iconSize = CGSize(width: 24.0, height: 24.0)
    private let inputFont = UIFont.systemFont(ofSize: 16.0)
    
    private var textInputHeight = IMInputLayout.minTextInputHeight
    private var inputLayoutHeight: CGFloat {
        get {
            var replyMsgHeight = 0.0
            if (self.isReplyMsgShow) {
                replyMsgHeight = 40.0
            }
            if (self.isSpeakViewShow) {
                return IMInputLayout.minTextInputHeight + replyMsgHeight + 20.0
            }            
            return self.textInputHeight + replyMsgHeight + 20.0
        }
    }
    
    private var isEmojiPanelShow = false
    private var isMorePanelShow = false
    
    private var isEmojiImageShow = true
    
    private var isSpeakViewShow = false
    private var isSpeakImageShow = false
    private var isReplyMsgShow = false
    
    private var disposeBag = DisposeBag()
    private var isKeyboardShow = false
    private var atMap = [String: String]()
    private var atRanges = [NSRange]()
    private var reeditMsg: Message? = nil
    
    lazy private var replyView: IMReplyView = {
        let view = IMReplyView()
        return view
    }()
    
    lazy private var speakButton: UIButton = {
        let voiceButton = UIButton()
        let image = SVGImageUtils.loadSVG(named: "ic_msg_voice")?.scaledToSize(iconSize)
        if image != nil {
            voiceButton.setImage(image!, for: .normal)
            voiceButton.contentHorizontalAlignment = .fill
            voiceButton.contentVerticalAlignment = .fill
            voiceButton.imageView?.contentMode = .scaleAspectFill
            voiceButton.clipsToBounds = true
        }
        return voiceButton
    }()
    
    lazy private var textView: IMTextView = {
        let textView = IMTextView()
        textView.delegate = self
        textView.placeholder = "说点什么.."
        textView.isScrollEnabled = true
        textView.textColor = UIColor.init(hex: "#333333")
        textView.font = inputFont
        textView.returnKeyType = .send
        textView.keyboardType = .default
        textView.backgroundColor = IMUIManager.shared.uiResourceProvider?.inputBgColor()
        textView.layer.cornerRadius = 20
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        textView.layer.masksToBounds = true
        textView.showsVerticalScrollIndicator = false
        textView.showsHorizontalScrollIndicator = false
        return textView
    }()
    
    lazy private var speakView: IMSpeakView = {
        let speakView = IMSpeakView()
        speakView.sender = self.sender
        return speakView
    }()
    
    lazy private var emojiButton: UIButton = {
        let emojiButton = UIButton()
        let image = SVGImageUtils.loadSVG(named: "ic_msg_emoji")?.scaledToSize(iconSize)
        if image != nil {
            emojiButton.setImage(image!, for: .normal)
            emojiButton.contentHorizontalAlignment = .fill
            emojiButton.contentVerticalAlignment = .fill
            emojiButton.imageView?.contentMode = .scaleAspectFill
            emojiButton.clipsToBounds = true
        }
        return emojiButton
    }()
    
    lazy private var moreButton: UIButton = {
        let moreButton = UIButton()
        let image = SVGImageUtils.loadSVG(named: "ic_msg_more")?.scaledToSize(iconSize)
        if image != nil {
            moreButton.setImage(image!, for: .normal)
            moreButton.contentHorizontalAlignment = .fill
            moreButton.contentVerticalAlignment = .fill
            moreButton.imageView?.contentMode = .scaleAspectFill
            moreButton.clipsToBounds = true
        }
        return moreButton
    }()
    
    lazy private var inputLayout: UIView = {
        let inputLayout = UIView()
        inputLayout.addSubview(self.textView)
        inputLayout.addSubview(self.speakView)
        inputLayout.addSubview(self.emojiButton)
        inputLayout.addSubview(self.moreButton)
        inputLayout.addSubview(self.replyView)
        inputLayout.addSubview(self.speakButton)
        
        return inputLayout
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.inputLayout)
        self.setupEvent()
        self.resetLayout()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupEvent() {
        self.textView.backwardDelegate = self
        self.speakButton.rx.tapGesture().when(.ended)
            .subscribe(onNext: {[weak self]  event in
                guard let sf = self else {
                    return
                }
                sf.isSpeakViewShow = !sf.isSpeakViewShow
                sf.isEmojiPanelShow = false
                sf.isMorePanelShow = false
                sf.resetLayout()
                sf.sender?.closeBottomPanel()
            })
            .disposed(by: disposeBag)
        
        self.emojiButton.rx.tapGesture().when(.ended)
            .subscribe(onNext: { [weak self]  event in
                guard let sf = self else {
                    return
                }
                sf.isSpeakViewShow = false
                sf.isEmojiPanelShow = !sf.isEmojiPanelShow
                sf.resetLayout()
                if sf.isEmojiPanelShow {
                    sf.isMorePanelShow = !sf.isEmojiPanelShow
                    sf.sender?.showBottomPanel(0)
                } else {
                    sf.openKeyboard()
                }
            })
            .disposed(by: disposeBag)
        
        self.moreButton.rx.tapGesture().when(.ended)
            .subscribe(onNext: { [weak self]  event in
                guard let sf = self else {
                    return
                }
                sf.isSpeakViewShow = false
                sf.isMorePanelShow = !sf.isMorePanelShow
                sf.resetLayout()
                if sf.isMorePanelShow {
                    sf.isEmojiPanelShow = !sf.isMorePanelShow
                    sf.sender?.showBottomPanel(1)
                } else {
                    sf.openKeyboard()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func switchEmojiView() {
        if self.isEmojiImageShow == !self.isEmojiPanelShow {
            return
        }
        self.isEmojiImageShow = !self.isEmojiPanelShow
        if self.isEmojiImageShow {
            let image = SVGImageUtils.loadSVG(named: "ic_msg_emoji")?.scaledToSize(iconSize)
            if image != nil {
                self.emojiButton.setImage(image!, for: .normal)
            }
        } else {
            let image = SVGImageUtils.loadSVG(named: "ic_msg_keyboard")?.scaledToSize(iconSize)
            if image != nil {
                self.emojiButton.setImage(image!, for: .normal)
            }
        }
    }
    
    private func switchSpeakView() {
        if self.isSpeakImageShow == self.isSpeakViewShow {
            return
        }
        self.isSpeakImageShow = self.isSpeakViewShow
        if self.isSpeakImageShow {
            self.speakView.isHidden = false
            self.textView.isHidden = true
            let image = SVGImageUtils.loadSVG(named: "ic_msg_keyboard")?.scaledToSize(iconSize)
            if image != nil {
                self.speakButton.setImage(image!, for: .normal)
            }
            self.isMorePanelShow = false
            self.isEmojiPanelShow = false
        } else {
            self.speakView.isHidden = true
            self.textView.isHidden = false
            let image = SVGImageUtils.loadSVG(named: "ic_msg_voice")?.scaledToSize(iconSize)
            if image != nil {
                self.speakButton.setImage(image!, for: .normal)
            }
        }
    }
    
    public func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            self.sendInputContent()
            return false
        } else if (text == "@") {
            self.showAtSessionMemberPopup()
            return true
        }
        return true
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        if (textView.text.count == 0) {
            self.reeditMsg = nil
        }
        let textViewFrame = textView.frame
        let constraintSize = CGSizeMake(textViewFrame.size.width, CGFloat(MAXFLOAT))
        var size = textView.sizeThatFits(constraintSize)
        if size.height <= textViewFrame.size.height {
            if textViewFrame.size.height <= IMInputLayout.minTextInputHeight {
                size.height = textViewFrame.size.height
            }
        } else if size.height > textViewFrame.size.height {
            if size.height >= IMInputLayout.maxTextInputHeight {
                size.height = IMInputLayout.maxTextInputHeight
                textView.isScrollEnabled = true
            } else {
                textView.isScrollEnabled = false
            }
        }
        if self.textInputHeight != size.height {
            self.textInputHeight = size.height
            self.resetLayout()
        }
    }
    
    func resetLayout(_ showLatestMsg: Bool = true) {
        let spacing = 8
        let buttonSize = 30
        let bottom = (Int(IMInputLayout.minTextInputHeight)+20-buttonSize)/2
        
        var showSpeaker = true
        var showMoreButton = true
        if let session = self.sender?.getSession() {
            showSpeaker = session.functionFlag & IMChatFunction.Audio.rawValue != 0
            let functions = IMUIManager.shared.getBottomFunctionProviders(session: session)
            if functions.count == 0 {
                showMoreButton = false
            }
        }
        if !showSpeaker {
            self.speakButton.snp.remakeConstraints { make in
                make.bottom.equalToSuperview().offset(0)
                make.left.equalToSuperview().offset(0)
                make.width.equalTo(0)
                make.height.equalTo(0)
            }
        } else {
            self.speakButton.snp.remakeConstraints { make in
                make.bottom.equalToSuperview().offset(-bottom)
                make.left.equalToSuperview().offset(spacing)
                make.width.equalTo(buttonSize)
                make.height.equalTo(buttonSize)
            }
        }
        
        if !showMoreButton {
            self.moreButton.snp.remakeConstraints {  make in
                make.bottom.equalToSuperview().offset(0)
                make.right.equalToSuperview().offset(0)
                make.width.equalTo(0)
                make.height.equalTo(0)
            }
        } else {
            self.moreButton.snp.remakeConstraints {  make in
                make.bottom.equalToSuperview().offset(-bottom)
                make.right.equalToSuperview().offset(-spacing)
                make.width.equalTo(buttonSize)
                make.height.equalTo(buttonSize)
            }
        }
        
        self.emojiButton.snp.remakeConstraints{ [weak self] make in
            guard let sf = self else {
                return
            }
            make.bottom.equalToSuperview().offset(-bottom)
            make.right.equalTo(sf.moreButton.snp.left).offset(-spacing)
            make.width.equalTo(buttonSize)
            make.height.equalTo(buttonSize)
        }
        
        self.textView.snp.remakeConstraints {  [weak self] make in
            guard let sf = self else {
                return
            }
            make.bottom.equalToSuperview().offset(-10)
            make.left.equalTo(sf.speakButton.snp.right).offset(spacing)
            make.right.equalTo(sf.emojiButton.snp.left).offset(-spacing)           
            make.height.equalTo(sf.textInputHeight)
        }
        
        self.speakView.snp.remakeConstraints { [weak self] make in
            guard let sf = self else {
                return
            }
            make.bottom.equalToSuperview().offset(-10)
            make.left.equalTo(sf.speakButton.snp.right).offset(spacing)
            make.right.equalTo(sf.emojiButton.snp.left).offset(-spacing)
            make.height.equalTo(IMInputLayout.minTextInputHeight)
        }
        self.speakView.isHidden = !self.isSpeakViewShow
        
        var replyHeight = 0
        if self.isReplyMsgShow {
            replyHeight = 40
        }
        self.replyView.snp.remakeConstraints { make in
            make.bottom.equalTo(self.textView.snp.top)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(replyHeight)
        }
        self.replyView.resetLayout()
        
        self.inputLayout.snp.remakeConstraints {  make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(inputLayoutHeight)
        }
        
        self.switchSpeakView()
        self.switchEmojiView()
        self.snp.updateConstraints { [weak self](make) -> Void in
            guard let sf = self else {
                return
            }
            make.height.equalTo(sf.getLayoutHeight())
        }
    }
    
    public override func endEditing(_ force: Bool) -> Bool {
        if isKeyboardShow {
            return self.textView.endEditing(force)
        } else if isMorePanelShow || isEmojiPanelShow {
            isMorePanelShow = false
            isEmojiPanelShow = false
            self.resetLayout()
            return true
        } else {
            return false
        }
    }
    
    func onKeyboardChange(_ isShow: Bool, _ duration: Double, _ keyboardHeight: CGFloat) {
        self.isKeyboardShow = isShow
        if isShow {
            // 如果键盘显示
            self.isSpeakViewShow = false
            self.isMorePanelShow = false
            self.isEmojiPanelShow = false
        } else {
            if keyboardHeight <= 0 { // 高度为0 复位
                self.isMorePanelShow = false
                self.isEmojiPanelShow = false
            }
        }
        self.resetLayout()
    }
    
    func addInputText(_ text: String, _ atMap: [Int64: (User, SessionMember?)]? = nil) {
        if atMap != nil {
            for (_, v) in atMap! {
                self.addAtMap(v.0, v.1)
            }
        }
        let data = NSMutableString(string: self.textView.text)
        let selectedRange = self.textView.selectedRange
        if data.length == 0 {
            data.append(text)
        } else {
            data.insert(text, at: (selectedRange.location+selectedRange.length))
        }
        self.renderInputText(String(data))
        self.textViewDidChange(self.textView)
        let newRange = NSRange(location: (selectedRange.location+selectedRange.length + text.length), length: 0)
        self.textView.selectedRange = newRange
    }
    
    func deleteInputContent(_ count: Int) {
        self.textView.deleteBackward()
    }
    
    private func deleteAtText(_ count: Int) -> Bool {
        guard let text = self.textView.text else {
            return false
        }
        if text.count < count {
            return false
        }
        var selectedRange = self.textView.selectedRange
        if selectedRange.location == 0 && selectedRange.length == 0 {
            return false
        }
        var deleted = false
        let data = NSMutableString(string: self.textView.text)
        if selectedRange.length == 0 {
            selectedRange.location -= count+1
            selectedRange.length += count
        }
        var delRange = NSRange(location: selectedRange.location, length: selectedRange.length)
        for atRange in self.atRanges {
            if (atRange.contains(selectedRange.location) || atRange.contains(selectedRange.location+selectedRange.length)) {
                let atStart = atRange.location
                let atEnd = atRange.location + atRange.length
                let delStart = delRange.location
                let delEnd = delRange.location + delRange.length
                let start = min(atStart, delStart)
                let end = max(atEnd, delEnd)
                delRange = NSRange(location: start, length: end-start)
                deleted = true
            }
        }
        if deleted {
            data.replaceCharacters(in: delRange, with: "")
            self.renderInputText(String(data))
            self.textViewDidChange(self.textView)
            self.textView.scrollRectToVisible(
                CGRect(x: 0,
                       y: self.textView.contentSize.height-15,
                       width: self.textView.contentSize.width,
                       height: 10),
                animated: true
            )
        }
        return deleted
    }
    
    func sendInputContent() {
        guard let text = self.textView.text else {
            return
        }
        if (text.length == 0) {
            return
        }
        if let session = sender?.getSession() {
            if let draft = session.draft  {
                Observable.just(draft).flatMap { draft in
                    try? IMCoreManager.shared.database.sessionDao().updateSessionDraft(session.id, nil)
                    if let session = try? IMCoreManager.shared.database.sessionDao().findById(session.id) {
                        SwiftEventBus.post(IMEvent.SessionUpdate.rawValue, sender: session)
                    }
                    return Observable.just(true)
                }.compose(RxTransformer.shared.io2Main())
                    .subscribe { _ in
                        
                    }.disposed(by: self.disposeBag)
            }
        }
        let (_, atUIds) = AtStringUtils.replaceAtNickNamesToUIds(text) { [weak self] nickname in
            guard let sf = self else {
                return nil
            }
            for (k, v) in sf.atMap {
                if (v == nickname) {
                    if Int64(k) != nil {
                        return Int64(k)!
                    }
                }
            }
            if let sender = sf.sender {
                let id = sender.syncGetSessionMemberUserIdByNickname(nickname)
                if id != nil {
                    return id!
                }
            }
            return nil
        }
        if let reeditMsg = self.reeditMsg  {
            let content = IMReeditMsgData(sessionId: reeditMsg.sessionId, originId: reeditMsg.msgId, edit: text)
            self.sender?.sendMessage(MsgType.Reedit.rawValue, content, nil, nil)
            self.reeditMsg = nil
        } else {
            self.sender?.sendMessage(MsgType.Text.rawValue, text, nil, atUIds)
        }
        self.atRanges.removeAll()
        self.renderInputText("")
        self.textInputHeight = IMInputLayout.minTextInputHeight
        self.resetLayout(false)
    }
    
    func getInputContent() ->String? {
        return self.textView.text
    }
    
    @discardableResult func openKeyboard() -> Bool {
        return self.textView.becomeFirstResponder()
    }
    
    @discardableResult func closeKeyboard() -> Bool {
        return self.textView.endEditing(true)
    }
    
    func getLayoutHeight() -> CGFloat {
        return self.inputLayoutHeight
    }
    
    private func showAtSessionMemberPopup() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: { [weak self] in
            self?.sender?.openAtViewController()
        })
    }
    
    private func addAtMap(_ user: User, _ sessionMember: SessionMember?) {
        self.atMap["\(user.id)"] = IMUIManager.shared.nicknameForSessionMember(user, sessionMember)
    }
    
    private func atNickname(_ id: Int64) -> String? {
        return self.atMap["\(id)"]
    }
    
    func addAtSessionMember(user: User, sessionMember: SessionMember?) {
        self.addAtMap(user, sessionMember)
        guard let atNickname = self.atNickname(user.id) else {
            return
        }
        guard var content = self.textView.text else {
            return
        }
        let u16Content = NSString(string: content)
        var lastRange = self.textView.selectedRange
        lastRange.location -= 1
        lastRange.length = 1
        let lastInput = u16Content.substring(with: lastRange)
        let offset = u16Content.substring(to: lastRange.location+lastRange.length).count
        if (lastInput == "@") {
            content.insert(
                contentsOf: "\(atNickname) ",
                at: content.index(content.startIndex, offsetBy: offset)
            )
        } else {
            content.insert(
                contentsOf: "@\(atNickname) ",
                at: content.index(content.startIndex, offsetBy: offset)
            )
        }
        self.renderInputText(content)
        self.textViewDidChange(self.textView)
    }
    
    private func renderInputText(_ data: String) {
        guard let regex = try? NSRegularExpression(pattern: AtStringUtils.atRegular) else {
            return
        }
        let allRange = NSRange(data.startIndex..<data.endIndex, in: data)
        let attributedStr = NSMutableAttributedString(string: data)
        atRanges.removeAll()
        regex.matches(in: data, options: [], range: allRange).forEach { matchResult in
            var range = matchResult.range
            range.length += 1
            range.location -= 1
            atRanges.append(range)
        }
        
        attributedStr.addAttribute(
            .foregroundColor,
            value: UIColor.init(hex: "#333333"),
            range: allRange
        )
        attributedStr.addAttribute(
            .font,
            value: inputFont,
            range: allRange
        )
        if (atRanges.count > 0) {
            for atRange in atRanges {
                attributedStr.addAttribute(
                    .foregroundColor,
                    value: IMUIManager.shared.uiResourceProvider?.tintColor() ?? UIColor.init(hex: "#1390f4"),
                    range: atRange
                )
                attributedStr.addAttribute(
                    .font,
                    value: inputFont,
                    range: atRange
                )
            }
        }
        self.textView.textColor = UIColor.init(hex: "#333333")
        self.textView.text = data
        self.textView.attributedText = attributedStr
    }
    
    
    func onDeleted() -> Bool {
        if self.deleteAtText(1) {
            return true
        }
        return false
    }
    
    func showReplyMessage(_ msg: Message) {
        self.isReplyMsgShow = true
        self.replyView.setMessage(msg)
        self.resetLayout()
        if !isKeyboardShow {
            self.openKeyboard()
        }
    }
    
    func clearReplyMessage() {
        if self.isReplyMsgShow {
            self.isReplyMsgShow = false
            self.replyView.clearMessage()
            self.resetLayout()
        }
    }
    
    func getReplyMessage() -> Message? {
        return self.replyView.getReplyMessage()
    }
    
    func setReeditMessage(_ message: Message) {
        self.reeditMsg = message
        if var content = message.content {
            content = AtStringUtils.replaceAtUIdsToNickname(content, message.getAtUIds()) { [weak self] id in
                if let member = self?.sender?.syncGetSessionMemberInfo(id) {
                    self?.addAtMap(member.0, member.1)
                    return IMUIManager.shared.nicknameForSessionMember(member.0, member.1)
                }
                return "\(id)"
            }
            self.renderInputText(content)
            if let sender = self.sender {
                if !sender.isKeyboardShowing() {
                    sender.openKeyboard()
                }
            }
        }
    }
    
}
