//
//  LocalParticipant.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/2.
//

import CocoaLumberjack
import Foundation
import WebRTC

class LocalParticipant: BaseParticipant {

    private let audioEnable: Bool
    private let videoEnable: Bool
    var innerDataChannel: RTCDataChannel?
    private var pushStreamKey: String? = nil
    private var videoCapturer: RTCCameraVideoCapturer?
    private var currentDevice: AVCaptureDevice?
    private var fps = 30

    init(uId: Int64, roomId: String, role: Role, audioEnable: Bool = true, videoEnable: Bool = true)
    {
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
            let audioTrack = IMLiveManager.shared.factory.audioTrack(
                with: audioSource, trackId: "/Audio/\(self.roomId)/\(self.uId)")
            let transceiver = RTCRtpTransceiverInit()
            transceiver.direction = .sendOnly
            p.addTransceiver(with: audioTrack, init: transceiver)
            self.addAudioTrack(track: audioTrack)
        }

        if self.videoEnable && role == Role.Broadcaster {
            self.currentDevice = self.getFrontCameraDevice()
            if self.currentDevice == nil {
                return
            }

            let videoSource = IMLiveManager.shared.factory.videoSource()
            self.videoCapturer = RTCCameraVideoCapturer()
            self.videoCapturer?.delegate = videoSource

            let format = chooseFormat(currentDevice!)
            if format == nil {
                return
            }
            if format != nil {
                self.videoCapturer?.startCapture(
                    with: currentDevice!, format: format!, fps: Int(fps))
            }
            let videoTrack = IMLiveManager.shared.factory.videoTrack(
                with: videoSource, trackId: "/Video/\(self.roomId)/\(self.uId)")
            let transceiver = RTCRtpTransceiverInit()
            transceiver.direction = .sendOnly
            p.addTransceiver(with: videoTrack, init: transceiver)
            self.addVideoTrack(track: videoTrack)

            p.senders.forEach({ sender in
                if sender.track?.kind == "video" {
                    let parameters = sender.parameters
                    for e in parameters.encodings {
                        let minBitrate = 1024 * 1024
                        e.maxBitrateBps = (4 * minBitrate) as NSNumber
                        e.minBitrateBps = (minBitrate) as NSNumber
                    }
                    sender.parameters = parameters
                }
            })
        }

        let dcConfig = RTCDataChannelConfiguration()
        dcConfig.isOrdered = true
        dcConfig.maxRetransmits = 3
        self.innerDataChannel = p.dataChannel(forLabel: "", configuration: dcConfig)
        self.innerDataChannel?.delegate = self
    }

    override func onLocalSdpSetSuccess(_ sdp: RTCSessionDescription) {
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
        let formats = RTCCameraVideoCapturer.supportedFormats(for: device)
        for f in formats {
            if #available(iOS 16.0, *) {
                for p in f.supportedMaxPhotoDimensions {
                    DDLogInfo(
                        "LocalParticipant, device format \(p.width), \(p.height), \(f.maxISO), \(f.minISO)"
                    )
                    if p.width == 960 && p.height == 540 {
                        format = f
                        break
                    }
                }
            } else {
                DDLogInfo("LocalParticipant, device format \(f.maxISO), \(f.minISO)")
            }
        }
        return format
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
