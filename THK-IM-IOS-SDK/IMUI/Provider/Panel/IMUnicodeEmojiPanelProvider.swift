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

    open func icon(selected: Bool) -> UIImage? {
        return ResourceUtils.loadImage(named: "ic_msg_emoji")?.withTintColor(
            IMUIManager.shared.uiResourceProvider?.inputTextColor()
                ?? UIColor.init(hex: "333333"))
    }

    open func support(session: Session) -> Bool {
        return true
    }

}
