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
        return ResourceUtils.loadString("album", comment: "")
    }
    
    public func icon() -> UIImage? {
        return ResourceUtils.loadImage(named: "ic_msg_media")
    }
    
    public func click(sender: IMMsgSender?) {
        sender?.choosePhoto()
    }
    
    public func support(session: Session) -> Bool {
        return session.functionFlag & IMChatFunction.Image.rawValue != 0 || session.functionFlag & IMChatFunction.Video.rawValue != 0
    }
}
