//
//  IMEmojiView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/10.
//

import Foundation
import UIKit

class IMEmojiView: UIView {
    
    weak var sender: IMMsgSender?
    
    private let emojiController = IMEmojiController()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func currentController() -> UIViewController? {
        var next = self.next
        while(next != nil) {
            if next!.isKind(of: UIViewController.self) {
                return next as? UIViewController
            } else {
                next = next!.next
            }
        }
        return nil
    }
    
    func setUp(sender: IMMsgSender?) {
        self.sender = sender
        emojiController.sender = self.sender
        guard let selfController = self.currentController() else {
            return
        }
        selfController.addChild(emojiController)
        self.addSubview(emojiController.view)
        emojiController.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setDown() {
        emojiController.removeFromParent()
    }
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        setDown()
    }
}
