//
//  IMUIDefines.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/10/2.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import UIKit

public enum IMMsgPosType: Int {
    case Mid = 0,
         Left = 1,
        Right = 2
}

public class IMFile {
    var image: UIImage?
    var url: URL?
    var mimeType: String
    
    init(image: UIImage?, url: URL?, mimeType: String) {
        self.image = image
        self.url = url
        self.mimeType = mimeType
    }
}
