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
    private let moreFunctionHeight = 200.0
    
    private var panelLayoutHeight = 0.0
    
    private var isEmojiPanelShow = false
    private var isMorePanelShow = false
    private var isKeyboardShow = false
    
    private let emojiPanelView = IMEmojiPanelView()
    private let functionPanelView = IMFunctionPanelView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.emojiPanelView.isHidden = true
        self.functionPanelView.isHidden = true
        self.addSubview(self.emojiPanelView)
        self.addSubview(self.functionPanelView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        self.emojiPanelView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.functionPanelView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func getLayoutHeight() -> CGFloat {
        return panelLayoutHeight
    }
    
    func showBottomPanel(_ position: Int) {
        if position == 0 {
            if (!self.isEmojiPanelShow) {
                self.isEmojiPanelShow = true
                self.isMorePanelShow = false
                self.emojiPanelView.isHidden = false
                self.functionPanelView.isHidden = true
                self.emojiPanelView.sender = self.sender
                panelLayoutHeight = emojiHeight
            }
        } else {
            if (!self.isMorePanelShow) {
                self.isEmojiPanelShow = false
                self.isMorePanelShow = true
                self.emojiPanelView.isHidden = true
                self.functionPanelView.isHidden = false
                functionPanelView.sender = self.sender
                panelLayoutHeight = moreFunctionHeight
            }
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
        self.emojiPanelView.isHidden = true
        self.functionPanelView.isHidden = true
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
            self.emojiPanelView.isHidden = true
            self.functionPanelView.isHidden = true
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
