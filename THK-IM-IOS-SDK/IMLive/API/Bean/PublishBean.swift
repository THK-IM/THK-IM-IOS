//
//  PublishBean.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/2.
//

import Foundation

class PublishReqBean: Codable {
    let uid: String
    let roomId: String
    let offerSdp: String
    enum CodingKeys: String, CodingKey {
        case uid = "uid"
        case roomId = "room_id"
        case offerSdp = "offer_sdp"
    }
    
    init(uid: String, roomId: String, offerSdp: String) {
        self.uid = uid
        self.roomId = roomId
        self.offerSdp = offerSdp
    }
}

class PublishResBean: Codable {
    let answerSdp: String
    let streamKey: String
    
    enum CodingKeys: String, CodingKey {
        case answerSdp = "answer_sdp"
        case streamKey = "stream_key"
    }
    
    init(answerSdp: String, streamKey: String) {
        self.answerSdp = answerSdp
        self.streamKey = streamKey
    }
}
