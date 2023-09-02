//
//  BaseParticipant.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/2.
//

import Foundation
import WebRTC
import Moya
import RxSwift
import CocoaLumberjack

class BaseParticipant: NSObject, RTCPeerConnectionDelegate, RTCDataChannelDelegate {
    
    let uId: String
    let roomId: String
    let role: Role
    let liveApi = MoyaProvider<LiveApi>(plugins: [NetworkLoggerPlugin()])
    let disposeBag = DisposeBag()
    var peerConnection: RTCPeerConnection?
    private var audioTracks = [RTCAudioTrack]()
    private var videoTracks = [RTCVideoTrack]()
    private var dataChannels = [String: RTCDataChannel]()
    private var rtcVideoView: RTCEAGLVideoView?
    private var audioMuted: Bool = false
    private var videoMuted: Bool = false
    
    init(uId: String, roomId: String, role: Role) {
        self.uId = uId
        self.roomId = roomId
        self.role = role
    }
    
    open func initPeerConnection() {
        let config = RTCConfiguration()
        // Unified plan is more superior than planB
        config.sdpSemantics = .unifiedPlan
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let p = LiveManager.shared.factory.peerConnection(
            with: config,
            constraints: constraints,
            delegate: self
        )
        self.peerConnection = p
    }
    
    open func startPeerConnection() {
        guard let p = self.peerConnection else {
            return
        }
        var mandatoryConstraints = [String: String]()
        if self is LocalParticipant {
            mandatoryConstraints["OfferToReceiveAudio"] = "false"
            mandatoryConstraints["OfferToReceiveVideo"] = "false"
        } else {
            mandatoryConstraints["OfferToReceiveAudio"] = "true"
            mandatoryConstraints["OfferToReceiveVideo"] = "true"
        }
        mandatoryConstraints["googCpuOveruseDetection"] = "true"
        let mediaConstraints = RTCMediaConstraints(
            mandatoryConstraints: mandatoryConstraints,
            optionalConstraints: nil
        )
        p.offer(for: mediaConstraints) { [weak self] sdp, err in
            if err == nil && sdp != nil {
                if sdp!.type == RTCSdpType.offer {
                    self?.onLocalSdpCreated(sdp!)
                }
            }
        }
    }
    
    open func onLocalSdpCreated(_ sdp: RTCSessionDescription) {
        guard let p = self.peerConnection else {
            return
        }
        p.setLocalDescription(sdp) { [weak self] err in
            guard let sf = self else {
                return
            }
            guard let sdp = sf.peerConnection?.localDescription else {
                return
            }
            if err == nil {
                sf.onLocalSdpSetSuccess(sdp)
            }
        }
    }
    
    open func onLocalSdpSetSuccess(_ sdp: RTCSessionDescription) {
        
    }
    
    open func setRemoteSessionDescription(_ sdp: RTCSessionDescription) {
        guard let p = self.peerConnection else {
            return
        }
        p.setRemoteDescription(sdp) { err in
            if err != nil {
                print(err!)
            }
        }
    }
    
    open func attachViewRender(_ rtcVideoView: RTCEAGLVideoView) {
        DDLogInfo("peerConnection attachViewRender \(self)")
        if self.rtcVideoView != nil {
            detachViewRender()
        }
        self.rtcVideoView = rtcVideoView
        self.attach()
    }
    
    private func attach() {
        DDLogInfo("peerConnection attach \(self)")
        guard let view = self.rtcVideoView else {
            return
        }
        for videoTrack in videoTracks {
            videoTrack.add(view)
        }
    }
    
    open func detachViewRender() {
        DDLogInfo("peerConnection detachViewRender \(self)")
        self.detach()
        self.rtcVideoView = nil
    }
    
    private func detach() {
        DDLogInfo("peerConnection detach \(self) \(videoTracks.count)")
        guard let view = self.rtcVideoView else {
            return
        }
        for videoTrack in videoTracks {
            videoTrack.remove(view)
        }
    }
    
    func addAudioTrack(track: RTCAudioTrack) {
        self.audioTracks.append(track)
    }
    
    func addVideoTrack(track: RTCVideoTrack) {
        self.videoTracks.append(track)
        self.attach()
    }
    
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
    
    }
    
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        DDLogInfo("peerConnection didReceiveMessageWith \(self) \(buffer.data)")
        if buffer.isBinary {
            self.onNewBufferMessage(data: buffer.data)
        } else {
            self.onNewMessage(data: buffer.data)
        }
    }
    
    private func onNewBufferMessage(data: Data) {
        guard let room = LiveManager.shared.getRoom() else {
            return
        }
        room.receiveDcData(data)
    }
    
    private func onNewMessage(data: Data) {
        guard let room = LiveManager.shared.getRoom() else {
            return
        }
        do {
            let notify = try JSONDecoder().decode(NotifyBean.self, from: data)
            DDLogInfo("onNewMessage \(notify.type), \(notify.message)")
            switch notify.type {
            case NotifyType.NewStream.rawValue:
                let newStream = try JSONDecoder().decode(
                    NewStreamNotify.self, from: notify.message.data(using: .utf8) ?? Data())
                let role = newStream.role == Role.Broadcaster.rawValue ? Role.Broadcaster: Role.Audience
                let audioEnable = room.mode == Mode.Audio || room.mode == Mode.Video
                let videoEnable = room.mode == Mode.Video
                let participant = RemoteParticipant(
                    uId: newStream.uid,
                    roomId: newStream.roomId,
                    role: role,
                    subStreamKey: newStream.streamKey,
                    audioEnable: audioEnable,
                    videoEnable: videoEnable
                )
                DispatchQueue.main.async {
                    room.participantJoin(p: participant)
                }
                break
            case NotifyType.RemoveStream.rawValue:
                let removeStream = try JSONDecoder().decode(
                    RemoveStreamNotify.self, from: notify.message.data(using: .utf8) ?? Data())
                DispatchQueue.main.async {
                    room.participantLeave(roomId: removeStream.roomId, streamKey: removeStream.streamKey)
                }
                break
            case NotifyType.DataChannelMsg.rawValue:
                let dataChannelMsg = try JSONDecoder().decode(
                        DataChannelMsg.self, from: notify.message.data(using: .utf8) ?? Data())
                DispatchQueue.main.async {
                    room.receivedDcMsg(dataChannelMsg.uid, dataChannelMsg.text)
                }
                break
            default:
                DDLogError("onNewMessage unknown type \(notify.type)")
                break
            }
        } catch {
            DDLogError("onNewMessage \(error)")
        }
    }
    
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        DDLogInfo("peerConnectionShouldNegotiate \(self)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        DDLogInfo("peerConnection didChange RTCSignalingState: \(stateChanged) \(self)")
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        DDLogInfo("peerConnection didChange RTCIceConnectionState: \(newState) \(self)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCPeerConnectionState) {
        DDLogInfo("peerConnection didChange RTCPeerConnectionState: \(newState), \(RTCPeerConnectionState.connected) \(self)")
        switch newState {
        case RTCPeerConnectionState.new, RTCPeerConnectionState.connecting:
            break
        case RTCPeerConnectionState.connected:
            break
        case RTCPeerConnectionState.closed, RTCPeerConnectionState.disconnected, RTCPeerConnectionState.failed:
            self.onDisconnected()
            break
        default:
            break
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        DDLogInfo("peerConnection didRemove RTCMediaStream \(self)")
        if self is RemoteParticipant {
            if stream.videoTracks.count > 0 {
                DispatchQueue.main.async { [weak self] in
                    self?.detach()
                }
            }
            for a in stream.audioTracks {
                self.audioTracks.removeAll { t in
                    if a == t {
                        return true
                    }
                    return false
                }
            }
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        DDLogInfo("peerConnection didAdd RTCMediaStream \(self)")
        if self is RemoteParticipant {
            self.audioTracks.append(contentsOf: stream.audioTracks)
            self.videoTracks.append(contentsOf: stream.videoTracks)
            DispatchQueue.main.async { [weak self] in
                self?.attach()
            }
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd rtpReceiver: RTCRtpReceiver, streams mediaStreams: [RTCMediaStream]) {
        DDLogInfo("peerConnection didAdd RTCRtpReceiver \(self)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove rtpReceiver: RTCRtpReceiver) {
        DDLogInfo("peerConnection didRemove RTCRtpReceiver \(self)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        DDLogInfo("peerConnection didChange RTCIceGatheringState: \(newState)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        DDLogInfo("peerConnection didGenerate RTCIceCandidate: \(candidate)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        DDLogInfo("peerConnection didRemove RTCIceCandidate: \(candidates)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        self.dataChannels[dataChannel.label] = dataChannel
        dataChannel.delegate = self
    }
    
    func pushStreamKey() -> String? {
        return nil
    }

    func playStreamKey() -> String? {
        return nil
    }
    
    func setVideoMuted(_ muted: Bool) {
        for t in self.videoTracks {
            t.isEnabled = !muted
        }
        videoMuted = muted
    }
    
    func getVideoMuted() -> Bool {
        return videoMuted
    }
    
    func setAudioMuted(_ muted: Bool) {
        for t in self.audioTracks {
            t.isEnabled = !muted
        }
        audioMuted = muted
    }
    
    func getAudioMuted() -> Bool {
        return audioMuted
    }
    
    
    open func onDisconnected() {
        self.detachViewRender()
        self.videoTracks.removeAll()
        self.audioTracks.removeAll()
        for (_, dc) in self.dataChannels {
            dc.delegate = nil
            dc.close()
        }
    }
    
    open func leave() {
        self.peerConnection?.close()
        self.peerConnection = nil
    }
    
}
