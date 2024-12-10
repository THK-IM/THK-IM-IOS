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

    private let mediaParams: MediaParams
    private let audioEnable: Bool
    private let videoEnable: Bool
    var innerDataChannel: RTCDataChannel?
    private var pushStreamKey: String? = nil
    private var videoCapturer: RTCCameraVideoCapturer?
    private var currentDevice: AVCaptureDevice?

    init(
        uId: Int64, roomId: String, role: Int, mediaParams: MediaParams, audioEnable: Bool = true,
        videoEnable: Bool = true
    ) {
        self.mediaParams = mediaParams
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
            let constraints = LiveMediaConstraints.build(
                enable3a: true, enableCpu: true, enableGainControl: true, enableStereo: true
            )
            let audioSource = LiveRTCEngine.shared.factory.audioSource(with: constraints)
            let audioTrack = LiveRTCEngine.shared.factory.audioTrack(
                with: audioSource, trackId: "/Audio/\(self.roomId)/\(self.uId)"
            )
            let transceiver = RTCRtpTransceiverInit()
            transceiver.direction = .sendOnly
            p.addTransceiver(with: audioTrack, init: transceiver)
            self.addAudioTrack(track: audioTrack)

            let audioMaxBitrate = self.mediaParams.audioMaxBitrate
            p.senders.forEach({ sender in
                if sender.track?.kind == audioTrack.kind {
                    let parameters = sender.parameters
                    for e in parameters.encodings {
                        e.maxBitrateBps = audioMaxBitrate as NSNumber
                        e.minBitrateBps = (10 * 8 * 1024) as NSNumber  // 10KB
                    }
                    sender.parameters = parameters
                }
            })
        }

        if self.videoEnable && self.role == Role.Broadcaster.rawValue {
            let videoSource = LiveRTCEngine.shared.factory.videoSource()
            self.videoCapturer = RTCCameraVideoCapturer()
            if let videoProxy = LiveRTCEngine.shared.videoCaptureProxy(videoSource) {
                self.videoCapturer?.delegate = videoProxy
            }
            let videoTrack = LiveRTCEngine.shared.factory.videoTrack(
                with: videoSource, trackId: "/Video/\(self.roomId)/\(self.uId)"
            )
            let transceiver = RTCRtpTransceiverInit()
            transceiver.direction = .sendOnly
            p.addTransceiver(with: videoTrack, init: transceiver)
            self.addVideoTrack(track: videoTrack)
            let videoMaxBitrate = self.mediaParams.videoMaxBitrate
            p.senders.forEach({ sender in
                if sender.track?.kind == videoTrack.kind {
                    let parameters = sender.parameters
                    for e in parameters.encodings {
                        e.maxBitrateBps = videoMaxBitrate as NSNumber
                        e.minBitrateBps = (10 * 8 * 1024) as NSNumber  // 10KB
                    }
                    sender.parameters = parameters
                }
            })
            self.startCaptureVideo()
        }

        let dcConfig = RTCDataChannelConfiguration()
        dcConfig.isOrdered = true
        dcConfig.maxRetransmits = 3
        self.innerDataChannel = p.dataChannel(forLabel: "", configuration: dcConfig)
        self.innerDataChannel?.delegate = self
    }

    private func startCaptureVideo() {
        // 设置设备
        if let device = self.getFrontCameraDevice() {
            if let format = self.chooseFormat(device) {
                self.videoCapturer?.startCapture(
                    with: device, format: format, fps: Int(self.mediaParams.videoFps))
                self.currentDevice = device
                return
            }
        }
        if let device = self.getBackCameraDevice() {
            if let format = self.chooseFormat(device) {
                self.videoCapturer?.startCapture(
                    with: device, format: format, fps: Int(self.mediaParams.videoFps))
                self.currentDevice = device
                return
            }
        }
    }

    open override func onLocalSdpSetSuccess(_ sdp: RTCSessionDescription) {
        super.onLocalSdpSetSuccess(sdp)
        let offer = sdp.sdp
        guard let offerBase64 = offer.data(using: .utf8)?.base64EncodedString() else {
            return
        }
        RTCRoomManager.shared.liveApi
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
                onError: { [weak self] err in
                    self?.onError("publishStream", err)
                }
            ).disposed(by: self.disposeBag)

    }

    func sendVolume(volume: Double) -> Bool {
        if self.role != Role.Broadcaster.rawValue { return false }
        let volumeMsg = VolumeMsg(uId: self.uId, volume: volume)
        if let d = try? JSONEncoder().encode(volumeMsg) {
            if let text = String(data: d, encoding: .utf8) {
                return self.sendMessage(type: VolumeMsgType, text: text)
            }
        }
        return false
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
            self.onError("sendMessage", error)
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

    func switchCamera() -> Bool {
        var newDevice = self.getBackCameraDevice()
        if self.currentDevice?.position == .back {
            newDevice = self.getFrontCameraDevice()
        }
        if newDevice != nil {
            if let format = self.chooseFormat(newDevice!) {
                if self.currentDevice != nil {
                    self.videoCapturer?.stopCapture(completionHandler: { [weak self] in
                        guard let sf = self else { return }
                        sf.videoCapturer?.startCapture(
                            with: newDevice!, format: format, fps: sf.mediaParams.videoFps)
                    })
                } else {
                    self.videoCapturer?.startCapture(
                        with: newDevice!, format: format, fps: self.mediaParams.videoFps)
                }
                self.currentDevice = newDevice
                return true
            }
        }
        return false
    }

    private func chooseFormat(_ device: AVCaptureDevice) -> AVCaptureDevice.Format? {
        let formats = RTCCameraVideoCapturer.supportedFormats(for: device)
        var bestFormat: AVCaptureDevice.Format?

        for format in formats {
            var supportFps = false
            for range in format.videoSupportedFrameRateRanges {
                if Int(range.maxFrameRate) >= self.mediaParams.videoFps
                    && Int(range.minFrameRate) <= self.mediaParams.videoFps
                {
                    supportFps = true
                    break
                }
            }

            if !supportFps {
                continue
            }

            let description = format.formatDescription
            let dimensions = CMVideoFormatDescriptionGetDimensions(description)
            if dimensions.width >= Int32(self.mediaParams.videoWidth)
                && dimensions.height >= Int32(self.mediaParams.videoHeight)
            {
                print(
                    "Camera: \(dimensions.width), \(dimensions.width), \(self.mediaParams.videoFps), \(self.mediaParams.videoWidth) \(self.mediaParams.videoHeight)"
                )
                bestFormat = format
                break
            }
        }

        return bestFormat
    }

    open override func onDisconnected() {
        self.innerDataChannel?.delegate = nil
        self.innerDataChannel?.close()
        self.innerDataChannel = nil
    }

    open override func leave() {
        LiveRTCEngine.shared.clearVideoProxy()
        if self.currentDevice != nil {
            self.videoCapturer?.stopCapture()
        }
        self.videoCapturer = nil
        super.leave()
    }

}
