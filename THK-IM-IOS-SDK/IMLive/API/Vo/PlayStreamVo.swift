//
//  PlayStreamVo.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/2.
//

import Foundation

class PlayStreamReqVo: Codable {
    let uId: Int64
    let roomId: String
    let offerSdp: String
    let streamKey: String
    enum CodingKeys: String, CodingKey {
        case uId = "u_id"
        case roomId = "room_id"
        case offerSdp = "offer_sdp"
        case streamKey = "stream_key"
    }
    
    init(uId: Int64, roomId: String, offerSdp: String, streamKey: String) {
        self.uId = uId
        self.roomId = roomId
        self.offerSdp = offerSdp
        self.streamKey = streamKey
    }
}

class PlayStreamResVo: Codable {
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
