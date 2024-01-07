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

class IMInputLayout: UIView, UITextViewDelegate {
    weak var sender: IMMsgSender? = nil {
        didSet {
            self.speakView.sender = sender
        }
    }
    private static let maxTextInputHeight: CGFloat = 120.0
    private static let minTextInputHeight: CGFloat = 40.0
    
    private var textInputHeight = IMInputLayout.minTextInputHeight
    private var inputLayoutHeight: CGFloat {
        get {
            if (self.isSpeakViewShow) {
                return IMInputLayout.minTextInputHeight + 20
            }
            return self.textInputHeight + 20.0
        }
    }
    
    private var isEmojiPanelShow = false
    private var isMorePanelShow = false
    
    private var isEmojiImageShow = true
    
    private var isSpeakViewShow = false
    private var isSpeakImageShow = false
    
    private var disposeBag = DisposeBag()
    private var isKeyboardShow = false
    
    lazy private var speakButton: UIButton = {
        let voiceButton = UIButton()
        let image = UIImage(named: "ic_msg_voice")
        if image != nil {
            voiceButton.setImage(image!, for: .normal)
            voiceButton.contentHorizontalAlignment = .fill
            voiceButton.contentVerticalAlignment = .fill
            voiceButton.imageView?.contentMode = .scaleAspectFill
            voiceButton.clipsToBounds = true
        }
        return voiceButton
    }()
    
    lazy private var textView: UITextView = {
        let textView = UITextView()
        textView.delegate = self
        textView.isScrollEnabled = true
        textView.font = UIFont.systemFont(ofSize: 16.0)
        textView.returnKeyType = .send
        textView.keyboardType = .default
        textView.backgroundColor = UIColor.white
        textView.showsVerticalScrollIndicator = false
        textView.showsHorizontalScrollIndicator = false
        textView.contentInset = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        return textView
    }()
    
    lazy private var speakView: IMSpeakView = {
        let speakView = IMSpeakView()
        speakView.sender = self.sender
        return speakView
    }()
    
    lazy private var emojiButton: UIButton = {
        let emojiButton = UIButton()
        let image = UIImage(named: "ic_msg_emoji")
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
        let image = UIImage(named: "ic_msg_more")
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
        let spacing = 8
        let buttonSize = 30
        let bottom = (Int(IMInputLayout.minTextInputHeight)+20-buttonSize)/2
        
        inputLayout.addSubview(self.speakButton)
        inputLayout.addSubview(self.textView)
        inputLayout.addSubview(self.speakView)
        inputLayout.addSubview(self.emojiButton)
        inputLayout.addSubview(self.moreButton)
        
        self.speakButton.snp.makeConstraints {  (make) -> Void in
            make.bottom.equalToSuperview().offset(-bottom)
            make.left.equalToSuperview().offset(spacing)
            make.width.equalTo(buttonSize)
            make.height.equalTo(buttonSize)
        }
        
        self.moreButton.snp.makeConstraints {  (make) -> Void in
            make.bottom.equalToSuperview().offset(-bottom)
            make.right.equalToSuperview().offset(-spacing)
            make.width.equalTo(buttonSize)
            make.height.equalTo(buttonSize)
        }
        
        self.emojiButton.snp.makeConstraints{ [weak self] (make) -> Void in
            guard let sf = self else {
                return
            }
            make.bottom.equalToSuperview().offset(-bottom)
            make.right.equalTo(sf.moreButton.snp.left).offset(-spacing)
            make.width.equalTo(buttonSize)
            make.height.equalTo(buttonSize)
        }
        
        self.textView.snp.makeConstraints {  [weak self] (make) -> Void in
            guard let sf = self else {
                return
            }
            make.bottom.equalToSuperview().offset(-10)
            make.left.equalTo(sf.speakButton.snp.right).offset(spacing)
            make.right.equalTo(sf.emojiButton.snp.left).offset(-spacing)
            make.height.equalTo(IMInputLayout.minTextInputHeight)
        }
        
        self.speakView.snp.makeConstraints {  [weak self] (make) -> Void in
            guard let sf = self else {
                return
            }
            make.bottom.equalToSuperview().offset(-10)
            make.left.equalTo(sf.speakButton.snp.right).offset(spacing)
            make.right.equalTo(sf.emojiButton.snp.left).offset(-spacing)
            make.height.equalTo(IMInputLayout.minTextInputHeight)
        }
        
        self.speakView.isHidden = !self.isSpeakViewShow
        
        return inputLayout
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.inputLayout)
        self.inputLayout.snp.makeConstraints {  (make) -> Void in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalToSuperview()
            make.height.equalTo(inputLayoutHeight)
        }
        self.setupEvent()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupEvent() {
        self.speakButton.rx.tap
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
        
        self.emojiButton.rx.tap
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
                    _ = sf.openKeyboard()
                }
            })
            .disposed(by: disposeBag)
        
        self.moreButton.rx.tap
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
                    _ = sf.openKeyboard()
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
            let image = UIImage(named: "ic_msg_emoji")
            if image != nil {
                self.emojiButton.setImage(image!, for: .normal)
            }
        } else {
            let image = UIImage(named: "ic_msg_keyboard")
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
            let image = UIImage(named: "ic_msg_keyboard")
            if image != nil {
                self.speakButton.setImage(image!, for: .normal)
            }
            self.isMorePanelShow = false
            self.isEmojiPanelShow = false
        } else {
            self.speakView.isHidden = true
            self.textView.isHidden = false
            let image = UIImage(named: "ic_msg_voice")
            if image != nil {
                self.speakButton.setImage(image!, for: .normal)
            }
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        // 判断是否是发送按钮被点击（根据换行符判断）
        if text == "\n" {
            self.sendInputContent()
            // 返回 false 以阻止输入换行符
            return false
        }
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
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
    
    private func resetLayout(_ showLatestMsg: Bool = true) {
        self.switchSpeakView()
        self.switchEmojiView()
        self.textView.snp.updateConstraints { [weak self](make) -> Void in
            guard let sf = self else {
                return
            }
            make.height.equalTo(sf.textInputHeight)
        }
        self.inputLayout.snp.updateConstraints {[weak self]  (make) -> Void in
            guard let sf = self else {
                return
            }
            make.height.equalTo(sf.inputLayoutHeight)
        }
        self.snp.updateConstraints { [weak self](make) -> Void in
            guard let sf = self else {
                return
            }
            make.height.equalTo(sf.getLayoutHeight())
        }
    }
    
    override func endEditing(_ force: Bool) -> Bool {
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
    
    func addInputText(_ text: String) {
        self.textView.scrollRangeToVisible(NSRange.init(location: self.textView.text.count, length: 1))
        self.textView.layoutManager.allowsNonContiguousLayout = false
        let content = self.textView.text
        if content == nil {
            self.textView.text = text
        } else {
            let range = self.textView.selectedRange
            let perStrIndex = content!.utf16.index(content!.utf16.startIndex, offsetBy: range.location)
            self.textView.text?.insert(contentsOf: text, at: perStrIndex)
            self.textView.selectedRange = NSRange(location: range.location+text.utf16.count, length: range.length)
        }
        self.textViewDidChange(self.textView)
        self.textView.scrollRectToVisible(
            CGRect(x: 0,
                   y: self.textView.contentSize.height-15,
                   width: self.textView.contentSize.width,
                   height: 10),
            animated: true
        )
    }
    
    func deleteInputContent(_ count: Int) {
        guard let text = self.textView.text else {
            return
        }
        if text.count < count {
            return 
        }
        let endIndex = text.index(text.endIndex, offsetBy: -1)
        self.textView.text.remove(at: endIndex)
        self.textViewDidChange(self.textView)
        self.textView.scrollRectToVisible(
            CGRect(x: 0,
                   y: self.textView.contentSize.height-15,
                   width: self.textView.contentSize.width,
                   height: 10),
            animated: true
        )
    }
    
    func sendInputContent() {
        let textMessage = self.textView.text
        if (textMessage != nil && textMessage!.length > 0) {
            self.sender?.sendMessage(MsgType.TEXT.rawValue, textMessage!, nil)
            self.textView.text = nil
        }
        self.textInputHeight = IMInputLayout.minTextInputHeight
        self.resetLayout(false)
    }
    
    
    func openKeyboard() -> Bool {
        return self.textView.becomeFirstResponder()
    }
    
    func closeKeyboard() -> Bool {
        return self.textView.endEditing(true)
    }
    
    func getLayoutHeight() -> CGFloat {
        return self.inputLayoutHeight
    }
    
}
