//
//  IMEvent.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/27.
//

import Foundation
import RxSwift

/**
 * IM事件
 */
enum IMEvent: String {
    case OnlineStatusUpdate = "IMEventOnlineStatusUpdate",
         MsgsNew = "IMEventMsgsNew",
         MsgNew = "IMEventMsgNew",
         MsgUpdate = "IMEventMsgUpdate",
         MsgDelete = "IMEventMsgDelete",
         MsgUploadProgressUpdate = "MsgUploadProgressUpdate",
         SessionNew = "IMEventSessionNew",
         SessionUpdate = "IMEventSessionUpdate",
         SessionDelete = "IMEventSessionDelete"
}




