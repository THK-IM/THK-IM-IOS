//
//  IMCoreDefines.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/27.
//

import Foundation

public enum SignalStatus: Int {
    case Init = 0
    case
        Connecting = 1
    case
        Connected = 2
    case
        DisConnected = 3
}

public enum SessionStatus: Int {
    case Reject = 1
    case
        Silence = 2
}

/// IM事件
public enum IMEvent: String {
    case OnlineStatusUpdate = "IMEventOnlineStatusUpdate"
    case
        BatchMsgNew = "IMEventBatchMsgNew"
    case
        MsgNew = "IMEventMsgNew"
    case
        MsgUpdate = "IMEventMsgUpdate"
    case
        MsgDelete = "IMEventMsgDelete"
    case
        BatchMsgDelete = "IMEventBatchMsgDelete"
    case
        SessionMessageClear = "IMEventSessionMessageClear"
    case
        SessionNew = "IMEventSessionNew"
    case
        SessionUpdate = "IMEventSessionUpdate"
    case
        SessionDelete = "IMEventSessionDelete"
    case
        MsgLoadStatusUpdate = "IMEventMsgLoadStatusUpdate"
}

public enum IMFileFormat: String {
    case Image = "image"
    case
        Video = "video"
    case
        Audio = "audio"
    case
        Doc = "doc"
    case
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
    case Upload = "upload"
    case
        Download = "download"
}

public enum IMMsgResourceType: String {
    case Thumbnail = "thumbnail"
    case
        Source = "source"
}

public typealias IMSendMsgResult = (_: Message, _: Error?) -> Void

public protocol Crypto {
    func encrypt(_ text: String) -> String?
    func decrypt(_ cipherText: String) -> String?
}

class IMCache {
    
    let time: Int64
    let data: Any
    
    init(time: Int64, data: Any) {
        self.time = time
        self.data = data
    }
}
