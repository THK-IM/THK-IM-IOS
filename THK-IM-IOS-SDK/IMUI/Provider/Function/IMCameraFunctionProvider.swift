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
        return "拍摄"
    }
    
    public func icon() -> UIImage? {
        return UIImage.init(named: "ic_msg_camera")
    }
    
    public func click(sender: IMMsgSender?) {
        sender?.openCamera()
    }
}
