//
//  IMUnicodeEmojiPanelProvider.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/10.
//

import Foundation
import UIKit

open class IMUnicodeEmojiPanelProvider: IMBasePanelViewProvider {
    
    public func contentView(sender: IMMsgSender?) -> UIView {
        let view = IMUnicodeEmojiPanelView()
        view.sender = sender
        return view
    }
    
    
    public func icon(selected: Bool) -> UIImage {
        return UIImage(named: "chat_bar_emoji")!
    }
    
}

