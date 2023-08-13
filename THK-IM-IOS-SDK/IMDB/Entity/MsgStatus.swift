//
//  MsgStatus.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/14.
//

import Foundation

public enum MsgStatus: Int {
    case Init = 0,
         Uploading = 1,
         Sending = 2,
         SendFailed = 3,
         SendOrRSuccess = 4,
         AlreadyRead = 5,
         AlreadyReadInServer = 6,
         Deleted = 9
}
