//
//  IMPreviewer.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/10/29.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import UIKit

public protocol IMPreviewer: AnyObject {

    func previewMessage(
        _ controller: UIViewController, _ items: [Message], _ view: UIView, _ loadMore: Bool,
        _ defaultId: Int64)

    /// 预览消息记录
    func previewRecordMessage(
        _ controller: UIViewController, _ originSession: Session, _ message: Message)

    
    /// 设置token
    func setTokenForEndpoint(endPoint: String, token: String)
    
}
