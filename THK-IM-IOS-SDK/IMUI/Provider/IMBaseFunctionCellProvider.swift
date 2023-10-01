//
//  IMBaseFunctionCellProvider.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/9.
//

import Foundation
import UIKit

public protocol IMBaseFunctionCellProvider: AnyObject {
    
    func name() -> String
    
    func icon() -> UIImage?
    
    func click(sender: IMMsgSender?)
}
