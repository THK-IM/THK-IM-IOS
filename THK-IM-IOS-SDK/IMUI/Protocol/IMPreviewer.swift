//
//  IMPreviewer.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/10/29.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import UIKit

public protocol IMPreviewer: AnyObject  {
    
    func previewMessage(_ controller: UIViewController, items: [Message], view: UIView, defaultId: Int64)

}
