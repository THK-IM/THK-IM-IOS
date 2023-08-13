//
//  LiveManager.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/31.
//

import Foundation
import WebRTC

class LiveManager {
    
    static let shared = LiveManager()
    
    private let room = Room(id: "1", role: Role.Broadcaster)
    
    let factory:RTCPeerConnectionFactory
    private init() {
        RTCPeerConnectionFactory.initialize()
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        self.factory = RTCPeerConnectionFactory.init(
            encoderFactory: videoEncoderFactory,
            decoderFactory: videoDecoderFactory
        )
    }
    
    func endpoint() ->String {
        return "http://192.168.1.4:18100"
    }
    
    func selfId() ->String {
        return "1"
    }
    
    func joinRoom() {
        room.join()
    }
    
    func leaveRoom() {
        room.leave()
    }
    
    func currentRoom() -> Room {
        return room
    }
    
}
