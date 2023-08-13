//
//  IMPhotoFunction.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/9.
//

import Foundation
import UIKit

open class IMPhotoFunctionProvider: IMBaseFunctionCellProvider {
    
    public func name() -> String {
        return "照片"
    }
    
    public func icon() -> UIImage? {
        return UIImage.init(named: "chat_bar_voice")
    }
    
    public func onFunction(sender: IMMsgSender?) {
        sender?.choosePhoto()
    }
}
