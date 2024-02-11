//
//  LocalParticipant.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/2.
//

import Foundation
import WebRTC
import CocoaLumberjack

class LocalParticipant: BaseParticipant {
    
    private let audioEnable: Bool
    private let videoEnable: Bool
    var innerDataChannel: RTCDataChannel?
    private var pushStreamKey: String? = nil
    private var videoCapturer: RTCCameraVideoCapturer?
    private var currentDevice: AVCaptureDevice?
    
    init(uId: Int64, roomId: String, role: Role, audioEnable: Bool = true, videoEnable: Bool = true) {
        self.audioEnable = audioEnable
        self.videoEnable = videoEnable
        super.init(uId: uId, roomId: roomId, role: role)
    }
    
    
    override func initPeerConnection() {
        super.initPeerConnection()
        guard let p = self.peerConnection else {
            return
        }
        
        if self.audioEnable && role == Role.Broadcaster {
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
            let audioSource = IMLiveManager.shared.factory.audioSource(with: mediaConstraints)
            let audioTrack = IMLiveManager.shared.factory.audioTrack(with: audioSource, trackId: "/Audio/\(self.roomId)/\(self.uId)")
            let transceiver = RTCRtpTransceiverInit()
            transceiver.direction = .sendOnly
            p.addTransceiver(with: audioTrack, init: transceiver)
            self.addAudioTrack(track: audioTrack)
        }
        
        if self.videoEnable && role == Role.Broadcaster {
            currentDevice = self.getFrontCameraDevice()
            if currentDevice == nil {
                return
            }
            
            let videoSource = IMLiveManager.shared.factory.videoSource()
            self.videoCapturer = RTCCameraVideoCapturer()
            videoCapturer?.delegate = videoSource
            
            let format = RTCCameraVideoCapturer.supportedFormats(for: currentDevice!).first
//            let formats = RTCCameraVideoCapturer.supportedFormats(for: currentDevice!)
//            for f in formats {
//                if #available(iOS 16.0, *) {
//                    let p = f.supportedMaxPhotoDimensions.first
//                    if p?.width == 480 && p?.height == 360 {
//                        format = f
//                    }
//                    DDLogInfo("LocalParticipant, device format \(f.minISO), \(f.maxISO), \(f.supportedMaxPhotoDimensions)")
//                } else {
//                    DDLogInfo("LocalParticipant, device format \(f.minISO), \(f.maxISO)")
//                }
//            }
            let fps = 10
            if format != nil {
                videoCapturer?.startCapture(with: currentDevice!, format: format!, fps: Int(fps))
            }
            let videoTrack = IMLiveManager.shared.factory.videoTrack(with: videoSource, trackId: "/Video/\(self.roomId)/\(self.uId)")
            let transceiver = RTCRtpTransceiverInit()
            transceiver.direction = .sendOnly
            p.addTransceiver(with: videoTrack, init: transceiver)
            self.addVideoTrack(track: videoTrack)
        }
        
        let dcConfig = RTCDataChannelConfiguration()
        dcConfig.isOrdered = true
        dcConfig.maxRetransmits = 3
        self.innerDataChannel = p.dataChannel(forLabel: "", configuration: dcConfig)
        self.innerDataChannel?.delegate = self
        
        self.startPeerConnection()
    }
    
    override func onLocalSdpSetSuccess(_ sdp: RTCSessionDescription) {
        super.onLocalSdpSetSuccess(sdp)
        let offer = sdp.sdp
        guard let offerBase64 = offer.data(using: .utf8)?.base64EncodedString() else {
            return
        }
        
        IMLiveManager.shared.liveApi
            .publishStream(PublishStreamReqVo(uId: self.uId, roomId: self.roomId, offerSdp: offerBase64))
            .compose(RxTransformer.shared.io2Main())
            .subscribe(onNext: { [weak self] resp in
                let data = Data(base64Encoded: resp.answerSdp) ?? Data()
                let answer = String(data: data, encoding: .utf8) ?? ""
                let remoteSdp = RTCSessionDescription(type: .answer, sdp: answer)
                self?.setRemoteSessionDescription(remoteSdp)
            }, onError: { err in
                print(err)
            }).disposed(by: self.disposeBag)
                
    }
    
    func sendMessage(text: String) -> Bool {
        guard let channel = innerDataChannel else {
            return false
        }
        let msg = DataChannelMsg(uId: self.uId, text: text)
        do {
            let b = try JSONEncoder().encode(msg)
            let buffer = RTCDataBuffer(data: b, isBinary: false)
            return channel.sendData(buffer)
        } catch {
            DDLogInfo("sendMessage \(error)")
            return false
        }
    }
    
    func sendData(data: Data) -> Bool {
        guard let channel = innerDataChannel else {
            return false
        }
        let buffer = RTCDataBuffer(data: data, isBinary: true)
        return channel.sendData(buffer)
    }
    
    private func getFrontCameraDevice() -> AVCaptureDevice? {
        return self.getCameraDevice(position: .front)
    }
    
    private func getBackCameraDevice() -> AVCaptureDevice? {
        return self.getCameraDevice(position: .back)
    }
    
    private func getCameraDevice(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let discovery = AVCaptureDevice.DiscoverySession.init(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: position
        )
        for device in discovery.devices {
            if device.position == position {
                return device
            }
        }
        return nil
    }
    
    func currentCamera() -> Int {
        guard let currentDevice = self.currentDevice else {
            return 0
        }
        return currentDevice.position.rawValue
    }
    
    func switchCamera() {
        guard let currentDevice = self.currentDevice else {
            return
        }
        if currentDevice.position == .front {
            self.currentDevice = self.getBackCameraDevice()
        } else {
            self.currentDevice = self.getFrontCameraDevice()
        }
        if self.currentDevice == nil {
            return
        }
        let format = RTCCameraVideoCapturer.supportedFormats(for: self.currentDevice!).first
        if format == nil {
            return
        }
        self.videoCapturer?.startCapture(with: self.currentDevice!, format: format!, fps: 10)
    }
    
    override func onDisconnected() {
        self.innerDataChannel?.delegate = nil
        self.innerDataChannel?.close()
        self.innerDataChannel = nil
    }
    
    override func leave() {
        self.videoCapturer?.stopCapture()
        self.videoCapturer = nil
        super.leave()
    }
    
}
