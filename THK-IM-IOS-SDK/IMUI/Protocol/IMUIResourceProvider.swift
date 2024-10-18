//
//  IMUIResourceProvider.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/3/13.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation
import UIKit

public protocol IMUIResourceProvider {

    func avatar(user: User) -> UIImage?

    func unicodeEmojis() -> [String]?

    func msgBubble(message: Message, session: Session?) -> UIImage?

    func tintColor() -> UIColor?

    func inputBgColor() -> UIColor?

    func inputLayoutBgColor() -> UIColor?

    func supportFunction(_ session: Session, _ functionFlag: Int64) -> Bool

}
