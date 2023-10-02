//
//  IMCoreDefines.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/27.
//

import Foundation

/**
 * IM事件
 */
public enum IMEvent: String {
    case OnlineStatusUpdate = "IMEventOnlineStatusUpdate",
         BatchMsgNew = "IMEventBatchMsgNew",
         MsgNew = "IMEventMsgNew",
         MsgUpdate = "IMEventMsgUpdate",
         MsgDelete = "IMEventMsgDelete",
         SessionNew = "IMEventSessionNew",
         SessionUpdate = "IMEventSessionUpdate",
         SessionDelete = "IMEventSessionDelete",
         MsgLoadStatusUpdate = "IMEventMsgLoadStatusUpdate"
}

public enum IMFileFormat: String {
    case Image = "image",
         Video = "video",
         Audio = "audio",
         Doc = "doc",
         Other = "other"
}



public class IMLoadProgress: Codable {
    
    var type: String
    var key: String
    var state: Int
    var progress: Int
    
    init(_ type: String, _ key: String, _ state: Int, _ progress: Int) {
        self.type = type
        self.key = key
        self.state = state
        self.progress = progress
    }
    
    enum CodingKeys: String, CodingKey {
        case type = "type"
        case key = "key"
        case state = "state"
        case progress = "progress"
    }
}

public enum IMLoadType: String {
    case Upload = "upload",
         Download = "download"
}

public enum IMMsgResourceType: String {
    case Thumbnail = "thumbnail",
         Source = "source"
}



