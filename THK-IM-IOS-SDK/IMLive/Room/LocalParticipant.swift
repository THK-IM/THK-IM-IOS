//
//  LocalParticipant.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/1.
//

import Foundation
import WebRTC

class LocalParticipant: BaseParticipant {
    
    private let audioEnable: Bool
    private let videoEnable: Bool
    
    private var cameraCapture: RTCCameraVideoCapturer? = nil
    
    init(uId: String, channelId: String, audioEnable: Bool = true, videoEnable: Bool = true) {
        self.audioEnable = audioEnable
        self.videoEnable = videoEnable
        super.init(uId: uId, channelId: channelId)
    }
    
    
    override func initPeerConnection() {
        super.initPeerConnection()
        guard let p = self.getRTCPeerConnection() else {
            return
        }
        
        if self.audioEnable {
            var mandatoryConstraints = [String: String]()
            mandatoryConstraints["googEchoCancellation"] = "true"
            mandatoryConstraints["googNoiseSuppression"] = "true"
            mandatoryConstraints["googHighpassFilter"] = "true"
            mandatoryConstraints["googCpuOveruseDetection"] = "true"
            mandatoryConstraints["googAutoGainControl"] = "true"
            let mediaConstraints = RTCMediaConstraints(
                mandatoryConstraints: mandatoryConstraints,
                optionalConstraints: nil
            )
            let audioSource = LiveManager.shared.factory.audioSource(with: mediaConstraints)
            let audioTrack = LiveManager.shared.factory.audioTrack(with: audioSource, trackId: "/Audio/\(self.channelId)/\(self.uId)")
            let transceiver = RTCRtpTransceiverInit()
            transceiver.direction = .sendOnly
            p.addTransceiver(with: audioTrack, init: transceiver)
            self.addAudioTrack(track: audioTrack)
        }
        
        if self.videoEnable {
            let cameraDevices = RTCCameraVideoCapturer.captureDevices()
            var device = cameraDevices.first
            for d in cameraDevices {
                if d.position == .front {
                    device = d
                    break
                }
            }
            if device == nil {
                return
            }
            let videoSource = LiveManager.shared.factory.videoSource()
            let videoCapturer = RTCCameraVideoCapturer()
            videoCapturer.delegate = videoSource
            let format = RTCCameraVideoCapturer.supportedFormats(for: device!).last
            let fps = format!.videoSupportedFrameRateRanges.first?.maxFrameRate ?? 30
            let videoTrack = LiveManager.shared.factory.videoTrack(with: videoSource, trackId: "/Video/\(self.channelId)/\(self.uId)")
            
            let transceiver = RTCRtpTransceiverInit()
            transceiver.direction = .sendOnly
            p.addTransceiver(with: videoTrack, init: transceiver)
            self.addVideoTrack(track: videoTrack)
            
            videoCapturer.startCapture(with: device!, format: format!, fps: Int(fps))
            self.cameraCapture = videoCapturer
        }
        
        self.startPeerConnection()
    }
    
    override func onLocalSdpSetSuccess(_ sdp: RTCSessionDescription) {
        super.onLocalSdpSetSuccess(sdp)
        let offer = sdp.sdp
        guard let offerBase64 = offer.data(using: .utf8)?.base64EncodedString() else {
            return
        }
        
        self.liveApi.rx
            .request(.requestPublish(PublishReqBean(uid: self.uId, roomId: self.channelId, offerSdp: offerBase64)))
            .asObservable()
            .compose(DefaultRxTransformer.io2Main())
            .compose(DefaultRxTransformer.response2Bean(PublishResBean.self))
            .subscribe(onNext: { [weak self] bean in
                let data = Data(base64Encoded: bean.answerSdp) ?? Data()
                let answer = String(data: data, encoding: .utf8) ?? ""
                let remoteSdp = RTCSessionDescription(type: .answer, sdp: answer)
                self?.setRemoteSessionDescription(remoteSdp)
            }, onError: { err in
                print(err)
            }).disposed(by: self.disposeBag)
                
    }
    
    override func leave() {
        self.cameraCapture?.stopCapture()
        super.leave()
    }
    
}
