//
//  IMUIProtocolDefines.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/10/3.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation

public typealias AudioCallback = (_ db: Double, _ duration: Int, _ path: String, _ stopped: Bool) ->
    Void

public typealias IMContentResult = (_ result: [IMFile], _ canceled: Bool) -> Void
