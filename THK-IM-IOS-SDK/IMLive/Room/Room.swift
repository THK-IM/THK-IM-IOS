//
//  Room.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/2.
//

import Foundation
import WebRTC
import Moya
import CocoaLumberjack


class Room: NSObject {
    private let id: String
    private let uId: String
    let mode: Mode
    
    private var observers = [RoomObserver]()
    private var localParticipant: LocalParticipant? = nil
    private var remoteParticipants = [RemoteParticipant]()
    
    let liveApi = MoyaProvider<LiveApi>(plugins: [NetworkLoggerPlugin()])
     
    init(id: String, uId: String, mode: Mode, role: Role, members: Array<Member>) {
        self.id = id
        self.uId = uId
        self.mode = mode
        super.init()
        self.initLocalParticipant(role: role)
        self.initRemoteParticipants(members: members)
    }
    
    private func initLocalParticipant(role: Role) {
        localParticipant = LocalParticipant(
            uId: self.uId, roomId: self.id, role: role,
            audioEnable: mode.rawValue >= Mode.Audio.rawValue,
            videoEnable: mode.rawValue >= Mode.Video.rawValue
        )
    }
    
    private func initRemoteParticipants(members: Array<Member>) {
        for m in members {
            let role = m.role == Role.Broadcaster.rawValue ? Role.Broadcaster: Role.Audience
            let audioEnable = mode == Mode.Audio || mode == Mode.Video
            let videoEnable = mode == Mode.Video
            let p = RemoteParticipant(
                uId: m.uid, roomId: id, role: role, subStreamKey: m.streamKey,
                audioEnable: audioEnable, videoEnable: videoEnable
            )
            self.remoteParticipants.append(p)
        }
    }
    
    func participantJoin(p: BaseParticipant) {
        if (p is RemoteParticipant) {
            if (!remoteParticipants.contains(p as! RemoteParticipant)) {
                remoteParticipants.append(p as! RemoteParticipant)
            }
            notifyJoin(p)
        } else if (p is LocalParticipant) {
            if (self.localParticipant != p) {
                self.localParticipant = (p as! LocalParticipant)
            }
            notifyJoin(p)
        }
    }
    
    func participantLeave(roomId: String, streamKey: String) {
        DDLogInfo("participantLeave")
        if (roomId == self.id) {
            var p: BaseParticipant? = nil
            if (localParticipant != nil && localParticipant!.pushStreamKey() == streamKey) {
                p = localParticipant
            }
            if (p == nil) {
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
        if (p is LocalParticipant) {
            self.onLocalParticipantLeave(p as! LocalParticipant)
        } else if (p is RemoteParticipant) {
            self.onRemoteParticipantLeave(p as! RemoteParticipant)
        }
    }
    
    private func onLocalParticipantLeave(_ p: LocalParticipant) {
        if (localParticipant == p) {
            localParticipant = nil
        }
        notifyLeave(p)
    }

    private func onRemoteParticipantLeave(_ p: RemoteParticipant) {
        if (remoteParticipants.contains(p)) {
            remoteParticipants.removeAll { remoteParticipant in
                return remoteParticipant == p
            }
        }
        notifyLeave(p)
    }
    
    private func notifyJoin(_ p: BaseParticipant) {
        for o in self.observers {
            o.delegate?.join(p)
        }
    }

    private func notifyLeave(_ p: BaseParticipant) {
        for o in self.observers {
            o.delegate?.leave(p)
        }
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
    
    func setRole(role: Role) {
        if self.localParticipant != nil {
            if self.localParticipant!.role != role {
                self.localParticipant!.leave()
                self.localParticipant!.onDisconnected()
            } else {
                return
            }
        }
        self.initLocalParticipant(role: role)
        participantJoin(p: self.localParticipant!)
    }
    
    func getRole() -> Role? {
        return self.localParticipant?.role
    }
    
    func registerObserver(_ d: RoomDelegate) {
        let o = RoomObserver()
        o.delegate = d
        if !observers.contains(o) {
            observers.append(o)
        }
    }
    
    func unRegisterObserver(_ d: RoomDelegate) {
        observers.removeAll { ob in
            return ob.delegate != nil && ob.delegate! == d
        }
    }
    
    func sendMessage(_ text: String) -> Bool {
        guard let lp = self.localParticipant else {
            return false
        }
        let success = lp.sendMessage(text: text)
        if success {
            self.receivedDcMsg(self.uId, text)
        }
        return success
    }
    
    func sendBytes(_ data: Data) -> Bool {
        guard let lp = self.localParticipant else {
            return false
        }
        return lp.sendData(data: data)
    }


    func receivedDcMsg(_ uid: String, _ text: String) {
        observers.forEach { ob in
            ob.delegate?.onTextMsgReceived(uId: uid, text: text)
        }
    }
    
    func receiveDcData(_ data:Data) {
        observers.forEach { ob in
            ob.delegate?.onBufferMsgReceived(data: data)
        }
    }
    
    func switchCamera() {
        localParticipant?.switchCamera()
    }
    
    func destroy() {
        self.observers.removeAll()
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
