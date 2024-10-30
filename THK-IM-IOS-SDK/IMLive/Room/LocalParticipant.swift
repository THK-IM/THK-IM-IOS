//
//  LocalParticipant.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/2.
//

import CocoaLumberjack
import Foundation
import WebRTC

open class LocalParticipant: BaseParticipant {

    private let audioEnable: Bool
    private let videoEnable: Bool
    var innerDataChannel: RTCDataChannel?
    private var pushStreamKey: String? = nil
    private var videoCapturer: RTCCameraVideoCapturer?
    private var currentDevice: AVCaptureDevice?
    private var fps = 30

    init(uId: Int64, roomId: String, role: Int, audioEnable: Bool = true, videoEnable: Bool = true)
    {
        self.audioEnable = audioEnable
        self.videoEnable = videoEnable
        super.init(uId: uId, roomId: roomId, role: role)
    }

    open override func initPeerConnection() {
        super.initPeerConnection()
        guard let p = self.peerConnection else {
            return
        }
        if self.audioEnable && self.role == Role.Broadcaster.rawValue {
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
            let audioSource = IMLiveRTCEngine.shared.factory.audioSource(with: mediaConstraints)
            let audioTrack = IMLiveRTCEngine.shared.factory.audioTrack(
                with: audioSource, trackId: "/Audio/\(self.roomId)/\(self.uId)"
            )
            let transceiver = RTCRtpTransceiverInit()
            transceiver.direction = .sendOnly
            p.addTransceiver(with: audioTrack, init: transceiver)
            self.addAudioTrack(track: audioTrack)
            p.senders.forEach({ sender in
                if sender.track?.kind == audioTrack.kind {
                    let parameters = sender.parameters
                    for e in parameters.encodings {
                        let minBitrate = 8 * 10 * 1024
                        e.maxBitrateBps = (5 * minBitrate) as NSNumber  // 50KB
                        e.minBitrateBps = (minBitrate) as NSNumber  // 10KB
                    }
                    sender.parameters = parameters
                }
            })
        }

        if self.videoEnable && self.role == Role.Broadcaster.rawValue {
            if let device = self.getFrontCameraDevice() {
                self.currentDevice = device
                let videoSource = IMLiveRTCEngine.shared.factory.videoSource()
                self.videoCapturer = RTCCameraVideoCapturer()
                if let videoProxy = IMLiveRTCEngine.shared.videoCaptureProxy(videoSource) {
                    self.videoCapturer?.delegate = videoProxy
                }

                if let format = self.chooseFormat(device) {
                    self.videoCapturer?.startCapture(
                        with: device, format: format, fps: Int(fps))
                    let videoTrack = IMLiveRTCEngine.shared.factory.videoTrack(
                        with: videoSource, trackId: "/Video/\(self.roomId)/\(self.uId)"
                    )
                    let transceiver = RTCRtpTransceiverInit()
                    transceiver.direction = .sendOnly
                    p.addTransceiver(with: videoTrack, init: transceiver)
                    self.addVideoTrack(track: videoTrack)

                    p.senders.forEach({ sender in
                        if sender.track?.kind == videoTrack.kind {
                            let parameters = sender.parameters
                            for e in parameters.encodings {
                                let minBitrate = 8 * 50 * 1024
                                e.maxBitrateBps = (10 * minBitrate) as NSNumber  // 500KB
                                e.minBitrateBps = (minBitrate) as NSNumber  // 50KB
                            }
                            sender.parameters = parameters
                        }
                    })
                }
            }
        }

        let dcConfig = RTCDataChannelConfiguration()
        dcConfig.isOrdered = true
        dcConfig.maxRetransmits = 3
        self.innerDataChannel = p.dataChannel(forLabel: "", configuration: dcConfig)
        self.innerDataChannel?.delegate = self
    }

    open override func onLocalSdpSetSuccess(_ sdp: RTCSessionDescription) {
        super.onLocalSdpSetSuccess(sdp)
        let offer = sdp.sdp
        guard let offerBase64 = offer.data(using: .utf8)?.base64EncodedString() else {
            return
        }
        IMLiveManager.shared.liveApi
            .publishStream(
                PublishStreamReqVo(uId: self.uId, roomId: self.roomId, offerSdp: offerBase64)
            )
            .compose(RxTransformer.shared.io2Main())
            .subscribe(
                onNext: { [weak self] resp in
                    let data = Data(base64Encoded: resp.answerSdp) ?? Data()
                    let answer = String(data: data, encoding: .utf8) ?? ""
                    let remoteSdp = RTCSessionDescription(type: .answer, sdp: answer)
                    self?.setRemoteSessionDescription(remoteSdp)
                },
                onError: { err in
                    print(err)
                }
            ).disposed(by: self.disposeBag)

    }

    func sendVolume(volume: Double) {
        let volumeMsg = VolumeMsg(uId: self.uId, volume: volume)
        if let d = try? JSONEncoder().encode(volumeMsg) {
            if let text = String(data: d, encoding: .utf8) {
                _ = self.sendMessage(type: VolumeMsgType, text: text)
            }
        }
    }

    func sendMessage(type: Int, text: String) -> Bool {
        guard let channel = innerDataChannel else {
            return false
        }
        let msg = DataChannelMsg(type: type, text: text)
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
        let devices = RTCCameraVideoCapturer.captureDevices()
        for device in devices {
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
        let format = chooseFormat(self.currentDevice!)
        if format == nil {
            return
        }
        if format != nil {
            videoCapturer?.startCapture(with: self.currentDevice!, format: format!, fps: Int(fps))
        }
    }

    private func chooseFormat(_ device: AVCaptureDevice) -> AVCaptureDevice.Format? {
        var format = RTCCameraVideoCapturer.supportedFormats(for: device).first
        //        let formats = RTCCameraVideoCapturer.supportedFormats(for: device)
        //        for f in formats {
        //            if #available(iOS 16.0, *) {
        //                for p in f.supportedMaxPhotoDimensions {
        //                    DDLogInfo(
        //                        "LocalParticipant, device format \(p.width), \(p.height), \(f.maxISO), \(f.minISO)"
        //                    )
        //                    if p.width == 960 && p.height == 540 {
        //                        format = f
        //                        break
        //                    }
        //                }
        //            } else {
        //                DDLogInfo("LocalParticipant, device format \(f.maxISO), \(f.minISO)")
        //            }
        //        }
        return format
    }

    open override func onDisconnected() {
        self.innerDataChannel?.delegate = nil
        self.innerDataChannel?.close()
        self.innerDataChannel = nil
    }

    open override func leave() {
        IMLiveRTCEngine.shared.clearVideoProxy()
        self.videoCapturer?.stopCapture()
        self.videoCapturer = nil
        super.leave()
    }

}
