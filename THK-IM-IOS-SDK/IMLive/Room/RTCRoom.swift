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
    let mode: Int
    let ownerId: Int64
    let createTime: Int64
    let mediaParams: MediaParams
    weak var rtcCallback: RTCRoomCallBack? = nil
    private var localParticipant: LocalParticipant? = nil
    private var remoteParticipants = [RemoteParticipant]()

    init(
        id: String, ownerId: Int64, mode: Int, role: Int,
        createTime: Int64, mediaParams: MediaParams,
        participants: [ParticipantVo]?
    ) {
        self.id = id
        self.ownerId = ownerId
        self.mode = mode
        self.createTime = createTime
        self.mediaParams = mediaParams
        super.init()
        self.initLocalParticipant(role)
        self.initRemoteParticipants(participants)
    }

    private func initLocalParticipant(_ role: Int) {
        localParticipant = LocalParticipant(
            uId: RTCRoomManager.shared.myUId, roomId: self.id, role: role,
            mediaParams: self.mediaParams,
            audioEnable: self.audioEnable(), videoEnable: self.videoEnable()
        )
    }

    func audioEnable() -> Bool {
        return self.mode >= RoomMode.Audio.rawValue
    }

    func videoEnable() -> Bool {
        return self.mode == RoomMode.Video.rawValue
            || self.mode == RoomMode.VideoRoom.rawValue
    }

    private func initRemoteParticipants(_ participants: [ParticipantVo]?) {
        if participants == nil {
            return
        }
        for p in participants! {
            let audioEnable = self.audioEnable()
            let videoEnable = self.videoEnable()
            let p = RemoteParticipant(
                uId: p.uId, roomId: id, role: p.role, subStreamKey: p.streamKey,
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
            if localParticipant != nil
                && localParticipant!.pushStreamKey() == streamKey
            {
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
        rtcCallback?.onParticipantJoin(p)
    }

    private func notifyLeave(_ p: BaseParticipant) {
        rtcCallback?.onParticipantLeave(p)
    }

    func onDataMsgReceived(_ data: Data) {
        rtcCallback?.onDataMsgReceived(data)
    }

    func onTextMsgReceived(_ type: Int, _ text: String) {
        if type == VolumeMsgType {
            if let volumeMsg = try? JSONDecoder().decode(
                VolumeMsg.self, from: text.data(using: .utf8) ?? Data())
            {
                rtcCallback?.onParticipantVoice(volumeMsg.uId, volumeMsg.volume)
            }
        } else {
            rtcCallback?.onTextMsgReceived(type, text)
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

    func getLocalParticipant() -> BaseParticipant? {
        return localParticipant
    }

    func getRemoteParticipants() -> [BaseParticipant] {
        return remoteParticipants
    }

    func updateMyRole(role: Int) {
        if let p = self.localParticipant {
            if p.role == role {
                return
            }
            p.leave()
            p.onDisconnected()
        }
        self.initLocalParticipant(role)
        if let p = self.localParticipant {
            self.participantJoin(p: p)
        }
    }

    func getMyRole() -> Int? {
        return self.localParticipant?.role
    }

    func sendMessage(_ type: Int, _ text: String) -> Bool {
        guard let lp = self.localParticipant else {
            return false
        }
        let success = lp.sendMessage(type: type, text: text)
        return success
    }

    func sendBytes(_ data: Data) -> Bool {
        guard let lp = self.localParticipant else {
            return false
        }
        return lp.sendData(data: data)
    }

    func sendMyVolume(_ volume: Double) -> Bool {
        guard let lp = self.localParticipant else {
            return false
        }
        let success = lp.sendVolume(volume: volume)
        if success {
            self.rtcCallback?.onParticipantVoice(RTCRoomManager.shared.myUId, volume)
        }
        return success
    }

    func switchCamera() -> Bool {
        return localParticipant?.switchCamera() ?? false
    }
    
    /**
     * rtc音频输入是否禁止
     */
    func isMicrophoneMuted() -> Bool {
        return LiveRTCEngine.shared.isMicrophoneMuted()
    }

    /**
     * 打开/关闭rtc音频输入
     */
    func muteMicrophone(_ mute: Bool) {
        LiveRTCEngine.shared.setMicrophoneMuted(mute)
    }

    /**
     * 扬声器是否打开
     */
    func isSpeakerOn() -> Bool {
        return LiveRTCEngine.shared.isSpeakerOn()
    }

    /**
     * 打开/关闭扬声器
     */
    func setSpeakerOn(_ on: Bool) {
        return LiveRTCEngine.shared.setSpeakerOn(on)
    }

    /**
     * 获取本地摄像头: 0 未知, 1 后置, 2 前置
     */
    func currentLocalCamera() -> Int {
        return self.localParticipant?.currentCamera() ?? 0
    }

    /**
     * 切换本地摄像头
     */
    func switchLocalCamera() {
        self.localParticipant?.switchCamera()
    }

    /**
     * 打开/关闭本地摄像头
     */
    func muteLocalVideoStream(mute: Bool) {
        self.localParticipant?.setVideoMuted(mute)
    }

    /**
     * 本地摄像头是否关闭
     */
    func isLocalVideoStreamMuted() -> Bool {
        return self.localParticipant?.getVideoMuted() ?? true
    }

    /**
     * 打开/关闭本地音频
     */
    func muteLocalAudioStream(mute: Bool) {
        self.localParticipant?.setAudioMuted(mute)
    }

    /**
     * 本地音频是否关闭
     */
    func isLocalAudioStreamMuted() -> Bool {
        return self.localParticipant?.getAudioMuted() ?? true
    }

    /**
     * 打开/关闭远端音频
     */
    func muteRemoteAudioStream(uId: Int64, mute: Bool) {
        for p in self.remoteParticipants {
            if p.uId == uId {
                p.setAudioMuted(mute)
            }
        }
    }

    /**
     * 打开/关闭远端音频
     */
    func muteAllRemoteAudioStream(mute: Bool) {
        for p in self.remoteParticipants {
            p.setAudioMuted(mute)
        }
    }

    /**
     * 远端音频是否关闭
     */
    func isRemoteAudioStreamMuted(uId: Int64) -> Bool {
        for p in self.remoteParticipants {
            if p.uId == uId {
                return p.getAudioMuted()
            }
        }
        return true
    }

    /**
     * 打开/关闭远端视频
     */
    func muteRemoteVideoStream(uId: Int64, mute: Bool) {
        for p in self.remoteParticipants {
            p.setVideoMuted(mute)
        }
    }

    /**
     * 打开/关闭所有远端视频
     */
    func muteAllRemoteVideoStream(mute: Bool) {
        for p in self.remoteParticipants {
            p.setVideoMuted(mute)
        }
    }

    /**
     * 远端视频是否关闭
     */
    func isRemoteVideoStreamMuted(uId: Int64) -> Bool {
        for p in self.remoteParticipants {
            if p.uId == uId {
                return p.getVideoMuted()
            }
        }
        return true
    }

    /**
     * 销毁房间
     */
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
