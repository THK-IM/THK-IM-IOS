//
//  IMBasePanelViewProvider.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/10.
//

import Foundation
import UIKit

public protocol IMBasePanelViewProvider: AnyObject {

    func icon(selected: Bool) -> UIImage?

    func contentView(sender: IMMsgSender?) -> UIView

    func support(session: Session) -> Bool
}
