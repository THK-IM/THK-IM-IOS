//
//  IMMsgPreviewer.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/3.
//

import UIKit

public protocol IMMsgPreviewer: AnyObject {
    ///  预览消息
    func previewMessage(_ msg: Message, _ position: Int, _ originView: UIView)
}
