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
    var data: Data
    var mimeType: String
    var name: String
    
    public init(data: Data, name: String, mimeType: String) {
        self.data = data
        self.mimeType = mimeType
        self.name = name
    }
}
