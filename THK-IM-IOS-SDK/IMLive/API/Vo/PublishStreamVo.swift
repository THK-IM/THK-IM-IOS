//
//  PublishStreamVo.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/2.
//

import Foundation

class PublishStreamReqVo: Codable {
    let uId: Int64
    let roomId: String
    let offerSdp: String
    enum CodingKeys: String, CodingKey {
        case uId = "u_id"
        case roomId = "room_id"
        case offerSdp = "offer_sdp"
    }
    
    init(uId: Int64, roomId: String, offerSdp: String) {
        self.uId = uId
        self.roomId = roomId
        self.offerSdp = offerSdp
    }
}

class PublishStreamRespVo: Codable {
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
