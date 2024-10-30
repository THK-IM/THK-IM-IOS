//
//  Room.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/2.
//

import CocoaLumberjack
import Foundation
import Moya
import WebRTC

public class RTCRoom: NSObject {
    let id: String
    let uId: Int64
    let mode: Int
    let ownerId: Int64
    let createTime: Int64
    weak var delegate: RTCRoomProtocol? = nil
    private var localParticipant: LocalParticipant? = nil
    private var remoteParticipants = [RemoteParticipant]()

    init(
        id: String, ownerId: Int64, uId: Int64, mode: Int, role: Role,
        createTime: Int64, participants: [ParticipantVo]?
    ) {
        self.id = id
        self.ownerId = ownerId
        self.uId = uId
        self.mode = mode
        self.createTime = createTime
        super.init()
        self.initLocalParticipant(role)
        self.initRemoteParticipants(participants)
    }

    private func initLocalParticipant(_ role: Role) {
        localParticipant = LocalParticipant(
            uId: self.uId, roomId: self.id, role: role,
            audioEnable: self.audioEnable(),
            videoEnable: self.videoEnable()
        )
    }
    
    private func audioEnable() -> Bool {
        return self.mode >= Mode.Audio.rawValue
    }
    
    private func videoEnable() -> Bool {
        return self.mode == Mode.Video.rawValue || self.mode == Mode.VideoRoom.rawValue
    }

    private func initRemoteParticipants(_ participants: [ParticipantVo]?) {
        if participants == nil {
            return
        }
        for p in participants! {
            let role = p.role == Role.Broadcaster.rawValue ? Role.Broadcaster : Role.Audience
            let audioEnable = self.audioEnable()
            let videoEnable = self.videoEnable()
            let p = RemoteParticipant(
                uId: p.uId, roomId: id, role: role, subStreamKey: p.streamKey,
                audioEnable: audioEnable, videoEnable: videoEnable
            )
            self.remoteParticipants.append(p)
        }
    }

    func participantJoin(p: BaseParticipant) {
        if p is RemoteParticipant {
            if !remoteParticipants.contains(p as! RemoteParticipant) {
                remoteParticipants.append(p as! RemoteParticipant)
            }
            notifyJoin(p)
        } else if p is LocalParticipant {
            if self.localParticipant != p {
                self.localParticipant = (p as! LocalParticipant)
            }
            notifyJoin(p)
        }
    }

    func participantLeave(roomId: String, streamKey: String) {
        if roomId == self.id {
            var p: BaseParticipant? = nil
            if localParticipant != nil && localParticipant!.pushStreamKey() == streamKey {
                p = localParticipant
            }
            if p == nil {
                for rp in remoteParticipants {
                    if rp.pushStreamKey() == streamKey {
                        p = rp
                        break
                    }
                }
            }
            if p != nil {
                p!.leave()
                self.onParticipantLeave(p!)
            }
        }
    }

    func onParticipantLeave(_ p: BaseParticipant) {
        if p is LocalParticipant {
            self.onLocalParticipantLeave(p as! LocalParticipant)
        } else if p is RemoteParticipant {
            self.onRemoteParticipantLeave(p as! RemoteParticipant)
        }
    }

    private func onLocalParticipantLeave(_ p: LocalParticipant) {
        if localParticipant == p {
            localParticipant = nil
        }
        notifyLeave(p)
    }

    private func onRemoteParticipantLeave(_ p: RemoteParticipant) {
        if remoteParticipants.contains(p) {
            remoteParticipants.removeAll { remoteParticipant in
                return remoteParticipant == p
            }
        }
        notifyLeave(p)
    }

    private func notifyJoin(_ p: BaseParticipant) {
        delegate?.onParticipantJoin(p)
    }
    
    private func notifyLeave(_ p: BaseParticipant) {
        delegate?.onParticipantLeave(p)
    }

    func onDataMsgReceived(_ uId: Int64, _ data: Data) {
        delegate?.onDataMsgReceived(uId, data)
    }
    
    func onTextMsgReceived(_ uId: Int64, _ text: String) {
        delegate?.onTextMsgReceived(uId, text)
    }

    func getAllParticipants() -> [BaseParticipant] {
        var participants = [BaseParticipant]()
        if localParticipant != nil {
            participants.append(localParticipant!)
        }
        for p in remoteParticipants {
            participants.append(p)
        }
        return participants
    }

    func getLocalParticipant() -> BaseParticipant? {
        return localParticipant
    }

    func getRemoteParticipants() -> [BaseParticipant] {
        return remoteParticipants
    }

    func setRole(role: Role) {
        if self.localParticipant != nil {
            if self.localParticipant!.role != role {
                self.localParticipant!.leave()
                self.localParticipant!.onDisconnected()
            } else {
                return
            }
        }
        self.initLocalParticipant(role)
        participantJoin(p: self.localParticipant!)
    }

    func getRole() -> Role? {
        return self.localParticipant?.role
    }

    func sendMessage(_ text: String) -> Bool {
        guard let lp = self.localParticipant else {
            return false
        }
        let success = lp.sendMessage(text: text)
        return success
    }

    func sendBytes(_ data: Data) -> Bool {
        guard let lp = self.localParticipant else {
            return false
        }
        return lp.sendData(data: data)
    }

    func switchCamera() {
        localParticipant?.switchCamera()
    }

    func destroy() {
        self.localParticipant?.onDisconnected()
        self.localParticipant?.leave()
        self.localParticipant = nil
        for remoteParticipant in remoteParticipants {
            remoteParticipant.onDisconnected()
            remoteParticipant.leave()
        }
        remoteParticipants.removeAll()
    }
}
