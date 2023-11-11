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
    
    private lazy var tabPanelView: IMTabPanelView = {
        let view = IMTabPanelView()
        return view
    }()
    
    private lazy var functionPanelView: IMFunctionPanelView = {
        let view = IMFunctionPanelView()
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
    
    func showBottomPanel(_ position: Int) {
        if position == 0 {
            if (!self.isEmojiPanelShow) {
                self.isEmojiPanelShow = true
                self.isMorePanelShow = false
                self.subviews.forEach {
                    $0.removeFromSuperview()
                }
                self.tabPanelView.sender = self.sender
                self.addSubview(self.tabPanelView)
                self.tabPanelView.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
                self.tabPanelView.initPosition()
                panelLayoutHeight = emojiHeight
            }
        } else {
            if (!self.isMorePanelShow) {
                self.isEmojiPanelShow = false
                self.isMorePanelShow = true
                self.subviews.forEach {
                    $0.removeFromSuperview()
                }
                self.functionPanelView.sender = self.sender
                self.addSubview(self.functionPanelView)
                self.functionPanelView.snp.makeConstraints { make in
                    make.edges.equalToSuperview()
                }
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
        self.tabPanelView.removeFromSuperview()
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
            self.tabPanelView.removeFromSuperview()
            self.functionPanelView.removeFromSuperview()
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
