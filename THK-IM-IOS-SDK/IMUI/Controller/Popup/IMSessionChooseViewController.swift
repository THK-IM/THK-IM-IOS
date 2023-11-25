//
//  SessionChoosePopView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/25.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import UIKit

class IMSessionChooseViewController: IMSessionViewController {
    
    var forwardType: Int?
    var messages: Array<Message>?
    
    public static func popup(vc: UIViewController, forwardType: Int, messages: Array<Message>) {
        let choose = IMSessionChooseViewController()
        choose.forwardType = forwardType
        choose.messages = messages
        let transition = CATransition.init()
        transition.duration = 0.4
        transition.type = .moveIn
        transition.subtype = .fromTop
        vc.navigationController?.view.layer.add(transition, forKey: kCATransition)
        vc.navigationController?.pushViewController(choose, animated: false)
    }
    
    override func openSession(_ session: Session) {
        guard let forwardType = self.forwardType else {
            return
        }
        guard let messages = self.messages else {
            return
        }
        if (forwardType == 0) { // 单条转发
            for m in messages {
                IMCoreManager.shared.getMessageModule().getMsgProcessor(m.type)
                    .forwardMessage(m, session.id)
            }
        } else { // 转发历史记录
            
        }
        self.pop()
    }
    
    private func buildRecordBody() {
    }
    
    
    private func pop() {
        let transition = CATransition.init()
        transition.duration = 0.4
        transition.type = .reveal
        transition.subtype = .fromBottom
        transition.timingFunction = CAMediaTimingFunction.init(name: .easeInEaseOut)
        self.navigationController?.view.layer.add(transition, forKey: kCATransition)
        self.navigationController?.popViewController(animated: false)
    }
    
    
    
    
}
