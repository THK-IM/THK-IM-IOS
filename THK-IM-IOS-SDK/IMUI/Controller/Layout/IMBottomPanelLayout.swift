//
//  BottomPanelLayout.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/2.
//

import Foundation
import UIKit

class IMBottomPanelLayout: UIView {
    
    weak var sender: IMMsgSender? = nil
    private let emojiHeight = 336.0
    private let moreFunctionHeight = 180.0
    
    private var panelLayoutHeight = 0.0
    
    private var isEmojiPanelShow = false
    private var isMorePanelShow = false
    private var isKeyboardShow = false
    
//    private lazy var unicodeEmojiView: IMUnicodeEmojiView = {
//        let view = IMUnicodeEmojiView()
//        view.emojiSelect = self
//        return view
//    }()
    
    private lazy var emojiView: IMEmojiView = {
        let view = IMEmojiView()
        return view
    }()
    
    private lazy var moreView: IMMoreView = {
        let view = IMMoreView()
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func getLayoutHeight() -> CGFloat {
        return panelLayoutHeight
    }
    
    // type: 1表情 2更多
    func showBottomPanel(_ type: Int) {
        if type == 1 {
            self.isEmojiPanelShow = true
            self.isMorePanelShow = false
            self.moreView.removeFromSuperview()
            self.addSubview(self.emojiView)
            self.emojiView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            self.emojiView.setUp(sender: self.sender)
            panelLayoutHeight = emojiHeight
        } else {
            self.isEmojiPanelShow = false
            self.isMorePanelShow = true
            self.emojiView.removeFromSuperview()
            self.moreView.sender = self.sender
            self.addSubview(self.moreView)
            self.moreView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            panelLayoutHeight = moreFunctionHeight
        }
        if isKeyboardShow {
            _ = self.sender?.closeKeyboard()
        } else {
            self.sender?.moveUpAlwaysShowView(false, panelLayoutHeight, 0.25)
        }
    }
    
    func closeBottomPanel() {
        self.isMorePanelShow = false
        self.isEmojiPanelShow = false
        self.emojiView.removeFromSuperview()
        panelLayoutHeight = 0.0
        if isKeyboardShow {
            _ = self.sender?.closeKeyboard()
        } else {
            self.sender?.moveUpAlwaysShowView(false, panelLayoutHeight, 0.25)
        }
    }
    
    private func resetLayout() {
        self.snp.updateConstraints { [weak self] make in
            guard let sf = self else {
                return
            }
            make.height.equalTo(sf.getLayoutHeight()) // 高度内部自己计算
        }
    }
    
    func onKeyboardChange(_ isShow: Bool, _ duration: Double, _ keyboardHeight: CGFloat) {
        self.isKeyboardShow = isShow
        if isShow {
            // 如果键盘显示
            self.isMorePanelShow = false
            self.isEmojiPanelShow = false
            self.emojiView.removeFromSuperview()
            self.moreView.removeFromSuperview()
            self.panelLayoutHeight = 0
        } else {
            // 如果键盘关闭
            if isEmojiPanelShow {
                panelLayoutHeight = emojiHeight
            } else if isMorePanelShow {
                panelLayoutHeight = moreFunctionHeight
            } else {
                panelLayoutHeight = 0
            }
        }
        self.resetLayout()
    }
    
    
    
}
