//
//  IMCoreDefines.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/27.
//

import Foundation
import RxSwift

/**
 * IM事件
 */
public enum IMEvent: String {
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

public enum IMFileFormat: String {
    case Image = "image",
         Video = "video",
         Audio = "audio",
         Doc = "doc",
         Other = "other"
}

public class IMUploadProgress: Codable {
    
    var key: String
    var state: Int
    var progress: Int
    
    init(_ key: String, _ state: Int, _ progress: Int) {
        self.key = key
        self.state = state
        self.progress = progress
    }
    
    enum CodingKeys: String, CodingKey {
        case key = "key"
        case state = "state"
        case progress = "progress"
    }
}





