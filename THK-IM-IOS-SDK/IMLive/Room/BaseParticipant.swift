//
//  BaseParticipant.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/1.
//

import Foundation
import WebRTC
import Moya
import RxSwift

class BaseParticipant: NSObject, RTCPeerConnectionDelegate, RTCDataChannelDelegate {
    
    let uId: String
    let channelId: String
    let liveApi = MoyaProvider<LiveApi>(plugins: [NetworkLoggerPlugin()])
    let disposeBag = DisposeBag()
    private var peerConnection: RTCPeerConnection?
    private var innerDataChannel: RTCDataChannel?
    private var audioTracks = [RTCAudioTrack]()
    private var videoTracks = [RTCVideoTrack]()
    private var dataChannels = [String: RTCDataChannel]()
    private var rtcVideoView: RTCEAGLVideoView?
    
    init(uId: String, channelId: String) {
        self.uId = uId
        self.channelId = channelId
    }
    
    func getRTCPeerConnection() -> RTCPeerConnection? {
        return self.peerConnection
    }
    
    open func setVideoEnable() {
        
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
        let dcConfig = RTCDataChannelConfiguration()
        dcConfig.isOrdered = true
        dcConfig.maxRetransmits = 3
        self.innerDataChannel = p.dataChannel(forLabel: "", configuration: dcConfig)
        self.innerDataChannel?.delegate = self
        
        var mandatoryConstraints = [String: String]()
        if self is LocalParticipant {
            mandatoryConstraints["OfferToReceiveAudio"] = "true"
            mandatoryConstraints["OfferToReceiveVideo"] = "true"
        } else {
            mandatoryConstraints["OfferToReceiveAudio"] = "false"
            mandatoryConstraints["OfferToReceiveVideo"] = "false"
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
        if self.rtcVideoView != nil {
            detachViewRender()
        }
        self.rtcVideoView = rtcVideoView
        self.attach()
    }
    
    private func attach() {
        guard let view = self.rtcVideoView else {
            return
        }
        for videoTrack in videoTracks {
            videoTrack.add(view)
        }
    }
    
    open func detachViewRender() {
        self.detach()
        self.rtcVideoView = nil
    }
    
    private func detach() {
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
    }
    
    open func leave() {
        self.detachViewRender()
        self.videoTracks.removeAll()
        self.audioTracks.removeAll()
        self.innerDataChannel?.delegate = nil
        self.innerDataChannel?.close()
        for (_, dc) in self.dataChannels {
            dc.delegate = nil
            dc.close()
        }
        self.peerConnection?.close()
    }
    
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
    
    }
    
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        if buffer.isBinary {
            
        } else {
            let msg = String(data: buffer.data, encoding: .utf8) ?? ""
            print(msg)
        }
    }
    
    
    
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        if self is RemoteParticipant {
            for v in stream.videoTracks {
                self.videoTracks.removeAll { t in
                    if v == t {
                        return true
                    }
                    return false
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
            DispatchQueue.main.async { [weak self] in
                self?.detach()
            }
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        if self is RemoteParticipant {
            self.audioTracks.append(contentsOf: stream.audioTracks)
            self.videoTracks.append(contentsOf: stream.videoTracks)
            DispatchQueue.main.async { [weak self] in
                self?.attach()
            }
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        self.dataChannels[dataChannel.label] = dataChannel
        dataChannel.delegate = self
    }
    
}
