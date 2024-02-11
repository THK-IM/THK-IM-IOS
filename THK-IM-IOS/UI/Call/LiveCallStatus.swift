//
//  LiveCallStatus.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/2/7.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

public enum LiveCallStatus: Int8 {
    case Init = 0,
         RequestCall = 1,   // 请求通话
         BeCalling = 2,     // 被请求通话
         Calling = 3        // 通话中
}
