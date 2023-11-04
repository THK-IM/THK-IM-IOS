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
         BatchMsgDelete = "IMEventBatchMsgDelete",
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
    var url: String
    var path: String
    var state: Int
    var progress: Int
    
    init(_ type: String, _ url: String, _ path: String, _ state: Int, _ progress: Int) {
        self.type = type
        self.url = url
        self.path = path
        self.state = state
        self.progress = progress
    }
    
    enum CodingKeys: String, CodingKey {
        case type = "type"
        case url = "url"
        case path = "path"
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



