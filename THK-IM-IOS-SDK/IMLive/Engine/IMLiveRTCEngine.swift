//
//  IMLiveRTCEngine.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/10/30.
//  Copyright © 2024 THK. All rights reserved.
//

import CocoaLumberjack
import Foundation
import WebRTC

public class IMLiveRTCEngine: NSObject {

    public static let shared = IMLiveRTCEngine()

    var factory: RTCPeerConnectionFactory
    private var audioProcessingModule: RTCDefaultAudioProcessingModule
    private var audioCaptureDelegate: RTCAudioCustomProcessingDelegate
    private var audioRenderDelegate: RTCAudioCustomProcessingDelegate
    private var videoCaptureDelegate: IMLiveVideoCapturerProxy?

    private override init() {
        RTCPeerConnectionFactory.initialize()
        self.audioRenderDelegate = IMLiveAudioRenderProxy()
        self.audioCaptureDelegate = IMLiveAudioCapturerProxy()

        let module = RTCDefaultAudioProcessingModule.init()
        // 录制时处理音频
        module.capturePostProcessingDelegate = self.audioCaptureDelegate
        // 播放时处理音频
        module.renderPreProcessingDelegate = self.audioRenderDelegate
        self.audioProcessingModule = module

        let videoProxy = IMLiveVideoCapturerProxy()
        self.videoCaptureDelegate = videoProxy

        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()

        let encodes = videoEncoderFactory.supportedCodecs()
        for c in encodes {
            if c.name == "VP8" {
                videoEncoderFactory.preferredCodec = c
            }
        }
        
        self.factory = RTCPeerConnectionFactory.init(
            bypassVoiceProcessing: true,
            encoderFactory: videoEncoderFactory,
            decoderFactory: videoDecoderFactory,
            audioProcessingModule: module
        )
        let option = RTCPeerConnectionFactoryOptions.init()
        self.factory.setOptions(option)
        super.init()
    }

    public func initAudioSession() {
        let audioSessionConfiguration = RTCAudioSessionConfiguration.webRTC()
        audioSessionConfiguration.category = AVAudioSession.Category.playAndRecord.rawValue
        audioSessionConfiguration.categoryOptions = [
            .defaultToSpeaker, .allowAirPlay, .allowBluetooth, .allowBluetoothA2DP,
        ]
        do {
            RTCAudioSession.sharedInstance().lockForConfiguration()
            try RTCAudioSession.sharedInstance().setConfiguration(
                audioSessionConfiguration, active: true
            )
            RTCAudioSession.sharedInstance().unlockForConfiguration()
        } catch {
            DDLogError("setConfiguration \(error)")
        }
    }

    public func isSpeakerMuted() -> Bool {
        let audioSession = AVAudioSession.sharedInstance()
        let currentRoute = audioSession.currentRoute
        var isSpeakerOutput = false
        for output in currentRoute.outputs {
            if output.portType == AVAudioSession.Port.builtInSpeaker {
                isSpeakerOutput = true
                break
            }
        }
        return !isSpeakerOutput
    }

    public func muteSpeaker(_ muted: Bool) {
        let audioSessionConfiguration = RTCAudioSessionConfiguration.webRTC()
        if muted {
            audioSessionConfiguration.categoryOptions = [
                .allowAirPlay, .allowBluetooth, .allowBluetoothA2DP,
            ]
        } else {
            audioSessionConfiguration.categoryOptions = [
                .defaultToSpeaker, .allowAirPlay, .allowBluetooth, .allowBluetoothA2DP,
            ]
        }
        do {
            RTCAudioSession.sharedInstance().lockForConfiguration()
            try RTCAudioSession.sharedInstance().setConfiguration(
                audioSessionConfiguration, active: true)
            RTCAudioSession.sharedInstance().unlockForConfiguration()
        } catch {
            DDLogError("setConfiguration \(error)")
        }
    }

    public func videoCaptureProxy(_ source: RTCVideoSource) -> RTCVideoCapturerDelegate? {
        self.videoCaptureDelegate?.videoSource = source
        return self.videoCaptureDelegate
    }

    public func clearVideoProxy() {
        self.videoCaptureDelegate?.videoSource = nil
    }

    public func updateVideoProxy(_ proxy: IMLiveVideoCapturerProxy?) {
        self.videoCaptureDelegate = proxy
    }

    public func updateAudioCaptureDelegate(_ delegate: RTCAudioCustomProcessingDelegate) {
        self.audioCaptureDelegate = delegate
        self.audioProcessingModule.capturePostProcessingDelegate = delegate
    }

    public func updateAudioRenderDelegate(_ delegate: RTCAudioCustomProcessingDelegate) {
        self.audioRenderDelegate = delegate
        self.audioProcessingModule.renderPreProcessingDelegate = delegate
    }

    public func onAudioCapture(_ samples: [Float], _ channel: Int) {
        let db = AudioUtils.calculateDecibel(from: samples)
        for r in RTCRoomManager.shared.allRooms() {
            r.sendMyVolume(db)
        }
    }
}
