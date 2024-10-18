//
//  IMBottomMore.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/9.
//

import Foundation
import UIKit

open class IMCameraFunctionProvider: IMBaseFunctionCellProvider {

    public func name() -> String {
        return ResourceUtils.loadString("camera", comment: "")
    }

    public func icon() -> UIImage? {
        return ResourceUtils.loadImage(named: "ic_msg_camera")
    }

    public func click(sender: IMMsgSender?) {
        sender?.openCamera()
    }

    public func support(session: Session) -> Bool {
        guard let provider = IMUIManager.shared.uiResourceProvider else {
            return false
        }
        return provider.supportFunction(session, IMChatFunction.Image.rawValue)
            || provider.supportFunction(session, IMChatFunction.Video.rawValue)
    }
}
