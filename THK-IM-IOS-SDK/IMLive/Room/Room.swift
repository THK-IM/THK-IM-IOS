//
//  Room.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/2.
//

import Foundation
import WebRTC

public enum Role: Int {
    case Broadcaster = 1,
         Audience = 2
}


class Room {
    
    private let id: String
    private let role: Role
    
    private var localParticipant: LocalParticipant? = nil
    private var remoteParticipants = [RemoteParticipant]()
     
    init(id: String, role: Role) {
        self.id = id
        self.role = role
    }
    
    func join() {
        if self.role == Role.Broadcaster {
            self.localParticipant = LocalParticipant(
                uId: LiveManager.shared.selfId(),
                channelId: self.id
            )
        }
        self.localParticipant?.initPeerConnection()
        for remoteParticipant in remoteParticipants {
            remoteParticipant.initPeerConnection()
        }
    }
    
    func leave() {
        self.localParticipant?.leave()
        for remoteParticipant in remoteParticipants {
            remoteParticipant.leave()
        }
    }
    
    
    func getLocalParticipant() -> LocalParticipant? {
        return self.localParticipant
    }
    
    func getRemoteParticipants() -> [RemoteParticipant] {
        return self.remoteParticipants
    }
}
