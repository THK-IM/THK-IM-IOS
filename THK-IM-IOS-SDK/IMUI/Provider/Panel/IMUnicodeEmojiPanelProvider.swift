//
//  IMUnicodeEmojiPanelProvider.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/10.
//

import Foundation
import UIKit

open class IMUnicodeEmojiPanelProvider: IMBasePanelViewProvider {
    
    open func contentView(sender: IMMsgSender?) -> UIView {
        let view = IMUnicodeEmojiPanelView()
        view.sender = sender
        return view
    }
    
    
    open func icon(selected: Bool) -> UIImage {
        return UIImage(named: "ic_msg_emoji")!
    }
    
    open func support(session: Session) -> Bool {
        return true
    }
    
}

