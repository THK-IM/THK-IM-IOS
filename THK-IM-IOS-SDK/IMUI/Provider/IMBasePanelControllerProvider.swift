//
//  IMBasePanelControllerProvider.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/10.
//

import Foundation
import UIKit

public protocol IMBasePanelControllerProvider: AnyObject {
    
    func icon(selected: Bool) -> UIImage
    
    func controller(sender: IMMsgSender?) -> UIViewController
}

