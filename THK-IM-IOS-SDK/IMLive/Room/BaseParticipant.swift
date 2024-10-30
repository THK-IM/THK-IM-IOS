//
//  BaseParticipant.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/2.
//

import CocoaLumberjack
import Foundation
import Moya
import RxSwift
import WebRTC

open class BaseParticipant: NSObject {

    let uId: Int64
    let roomId: String
    let role: Int
    let disposeBag = DisposeBag()
    var peerConnection: RTCPeerConnection?
    private var audioTracks = [RTCAudioTrack]()
    private var videoTracks = [RTCVideoTrack]()
    private var dataChannels = [String: RTCDataChannel]()
    private var rtcVideoView: RTCMTLVideoView?
    private var audioMuted: Bool = false
    private var videoMuted: Bool = false

    init(uId: Int64, roomId: String, role: Int) {
        self.uId = uId
        self.roomId = roomId
        self.role = role
    }

    open func pushStreamKey() -> String? {
        return nil
    }

    open func playStreamKey() -> String? {
        return nil
    }

    open func setVideoMuted(_ muted: Bool) {
        for t in self.videoTracks {
            t.isEnabled = !muted
        }
        videoMuted = muted
    }

    open func getVideoMuted() -> Bool {
        return videoMuted
    }

    open func setAudioMuted(_ muted: Bool) {
        for t in self.audioTracks {
            t.isEnabled = !muted
        }
        audioMuted = muted
    }

    open func getAudioMuted() -> Bool {
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

    /**
     *  初始化连接
     */
    open func initPeerConnection() {
        let config = RTCConfiguration()
        // Unified plan is more superior than planB
        config.sdpSemantics = .unifiedPlan
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let p = IMLiveManager.shared.factory.peerConnection(
            with: config,
            constraints: constraints,
            delegate: self
        )
        self.peerConnection = p
    }

    /**
     *  开始建立连接
     */
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
        mandatoryConstraints["googCpuOveruseDetection"] = "false"
        let mediaConstraints = RTCMediaConstraints(
            mandatoryConstraints: mandatoryConstraints,
            optionalConstraints: nil
        )
        p.offer(for: mediaConstraints) { [weak self] sdp, err in
            if err == nil {
                if sdp != nil && sdp!.type == RTCSdpType.offer {
                    self?.onLocalSdpCreated(sdp!)
                }
            } else {
                self?.onError("offer", err!)
            }
        }
    }

    /**
     *  本地sdp创建成功
     */
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
            } else {
                sf.onError("onLocalSdpSetSuccess", err!)
            }
        }
    }

    /**
     *  本地sdp设置成功
     */
    open func onLocalSdpSetSuccess(_ sdp: RTCSessionDescription) {

    }

    /**
     *  设置远端sdp
     */
    open func setRemoteSessionDescription(_ sdp: RTCSessionDescription) {
        guard let p = self.peerConnection else {
            return
        }
        p.setRemoteDescription(sdp) { [weak self] err in
            if err != nil {
                self?.onError("setRemoteDescription", err!)
            }
        }
    }

    /**
     *  RTCVideoView 绑定流
     */
    open func attachViewRender(_ rtcVideoView: RTCMTLVideoView) {
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

    /**
     *  RTCVideoView 解除流
     */
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
        self.attach()
    }

    private func onNewBufferMessage(data: Data) {
        guard let room = IMLiveManager.shared.getRoom() else {
            return
        }
        if room.id != self.roomId { return }
        room.onDataMsgReceived(self.uId, data)
    }

    private func onNewMessage(data: Data) {
        guard let room = IMLiveManager.shared.getRoom() else {
            return
        }
        if room.id != self.roomId { return }
        do {
            let notify = try JSONDecoder().decode(NotifyBean.self, from: data)
            switch notify.type {
            case NotifyType.NewStream.rawValue:
                let newStream = try JSONDecoder().decode(
                    NewStreamNotify.self,
                    from: notify.message.data(using: .utf8) ?? Data()
                )
                let participant = RemoteParticipant(
                    uId: newStream.uId,
                    roomId: newStream.roomId,
                    role: newStream.role,
                    subStreamKey: newStream.streamKey,
                    audioEnable: room.audioEnable(),
                    videoEnable: room.videoEnable()
                )
                DispatchQueue.main.async {
                    room.participantJoin(p: participant)
                }
                break
            case NotifyType.RemoveStream.rawValue:
                let removeStream = try JSONDecoder().decode(
                    RemoveStreamNotify.self, from: notify.message.data(using: .utf8) ?? Data())
                DispatchQueue.main.async {
                    room.participantLeave(
                        roomId: removeStream.roomId, streamKey: removeStream.streamKey)
                }
                break
            case NotifyType.DataChannelMsg.rawValue:
                let dataChannelMsg = try JSONDecoder().decode(
                    DataChannelMsg.self, from: notify.message.data(using: .utf8) ?? Data())
                DispatchQueue.main.async {
                    room.onTextMsgReceived(dataChannelMsg.uId, dataChannelMsg.text)
                }
                break
            default:
                DDLogError("Participant: onNewMessage unknown type \(notify.type)")
                break
            }
        } catch {
            DDLogError("Participant: onNewMessage \(error)")
        }
    }

    open func onError(_ function: String, _ err: Error) {
        guard let room = IMLiveManager.shared.getRoom() else {
            return
        }
        if room.id != self.roomId { return }
        room.delegate?.onError(function, err)
    }

}

extension BaseParticipant: RTCPeerConnectionDelegate {

    /**
     * RTC协商回调
     */
    public func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        DDLogInfo("peerConnectionShouldNegotiate \(self)")
    }

    /**
     * RTCSignaling状态改变回调
     */
    public func peerConnection(
        _ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState
    ) {
        DDLogInfo("peerConnection didChange RTCSignalingState: \(stateChanged) \(self)")

    }

    /**
     * RTC Ice连接状态改变回调
     */
    public func peerConnection(
        _ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState
    ) {
        DDLogInfo("peerConnection didChange RTCIceConnectionState: \(newState) \(self)")
    }

    /**
     * RTC 点对点连接状态改变回调
     */
    public func peerConnection(
        _ peerConnection: RTCPeerConnection, didChange newState: RTCPeerConnectionState
    ) {
        switch newState {
        case RTCPeerConnectionState.new, RTCPeerConnectionState.connecting:
            break
        case RTCPeerConnectionState.connected:
            break
        case RTCPeerConnectionState.closed, RTCPeerConnectionState.disconnected,
            RTCPeerConnectionState.failed:
            self.onDisconnected()
            break
        default:
            break
        }
    }

    /**
     * RTC 流移除回调
     */
    public func peerConnection(
        _ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream
    ) {
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

    /**
     * RTC 流添加回调
     */
    public func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        if self is RemoteParticipant {
            self.audioTracks.append(contentsOf: stream.audioTracks)
            self.videoTracks.append(contentsOf: stream.videoTracks)
            DispatchQueue.main.async { [weak self] in
                self?.attach()
            }
        }
    }

    /**
     * RTC 添加RTP接受者回调
     */
    public func peerConnection(
        peerConnection: RTCPeerConnection, didAdd rtpReceiver: RTCRtpReceiver,
        streams mediaStreams: [RTCMediaStream]
    ) {
        DDLogInfo("peerConnection didAdd RTCRtpReceiver \(self)")
    }

    /**
     * RTC 移除RTP接受者回调
     */
    public func peerConnection(
        _ peerConnection: RTCPeerConnection, didRemove rtpReceiver: RTCRtpReceiver
    ) {
        DDLogInfo("peerConnection didRemove RTCRtpReceiver \(self)")
    }

    /**
     * RTC Ice 状态变更
     */
    public func peerConnection(
        _ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState
    ) {
        DDLogInfo("peerConnection didChange RTCIceGatheringState: \(newState)")
    }

    /**
     * RTC Ice 生成回调
     */
    public func peerConnection(
        _ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate
    ) {
        DDLogInfo("peerConnection didGenerate RTCIceCandidate: \(candidate)")
    }

    /**
     * RTC Ice 移除回调
     */
    public func peerConnection(
        _ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]
    ) {
        DDLogInfo("peerConnection didRemove RTCIceCandidate: \(candidates)")
    }

}

extension BaseParticipant: RTCDataChannelDelegate {

    /**
     * RTC DataChannel打开回调
     */
    public func peerConnection(
        _ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel
    ) {
        self.dataChannels[dataChannel.label] = dataChannel
        dataChannel.delegate = self
    }

    open func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        if dataChannel.readyState == .closed {
            self.dataChannels.removeValue(forKey: dataChannel.label)
        }
    }

    public func dataChannel(
        _ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer
    ) {
        guard let room = IMLiveManager.shared.getRoom() else {
            return
        }
        if self.roomId == room.id {
            if buffer.isBinary {
                self.onNewBufferMessage(data: buffer.data)
            } else {
                self.onNewMessage(data: buffer.data)
            }
        }
    }

}
