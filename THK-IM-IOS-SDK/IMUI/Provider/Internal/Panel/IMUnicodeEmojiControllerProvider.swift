//
//  IMUnicodeEmojiControllerProvider.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/10.
//

import Foundation
import UIKit

open class IMUnicodeEmojiControllerProvider: IMBasePanelControllerProvider {
    
    public func icon(selected: Bool) -> UIImage {
        return UIImage(named: "chat_bar_emoji")!
    }
    
    public func controller(sender: IMMsgSender?) -> UIViewController {
        let vc = IMUnicodeEmojiUIController()
        vc.sender = sender
        return vc
    }
    
}

