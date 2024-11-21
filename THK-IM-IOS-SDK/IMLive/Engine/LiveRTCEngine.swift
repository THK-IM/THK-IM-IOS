//
//  LiveRTCEngine.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/10/30.
//  Copyright © 2024 THK. All rights reserved.
//

import CocoaLumberjack
import Foundation
import WebRTC

public class LiveRTCEngine: NSObject {

    public static let shared = LiveRTCEngine()

    var factory: RTCPeerConnectionFactory
    private var audioProcessingModule: RTCDefaultAudioProcessingModule
    private var audioCaptureDelegate: RTCAudioCustomProcessingDelegate
    private var audioRenderDelegate: RTCAudioCustomProcessingDelegate
    private var videoCaptureDelegate: LiveVideoCapturerProxy?

    private override init() {
        RTCPeerConnectionFactory.initialize()
        self.audioRenderDelegate = LiveAudioRenderProxy()
        self.audioCaptureDelegate = LiveAudioCapturerProxy()

        self.audioProcessingModule = RTCDefaultAudioProcessingModule.init()
        self.audioProcessingModule.capturePostProcessingDelegate = self.audioCaptureDelegate
        self.audioProcessingModule.renderPreProcessingDelegate = self.audioRenderDelegate

        let videoProxy = LiveVideoCapturerProxy()
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
            bypassVoiceProcessing: false,
            encoderFactory: videoEncoderFactory,
            decoderFactory: videoDecoderFactory,
            audioProcessingModule: self.audioProcessingModule
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

    /**
     * 扬声器外放是否打开
    */
    public func isSpeakerOn() -> Bool {
        let currentRoute = RTCAudioSession.sharedInstance().currentRoute
        var isSpeakerOutput = false
        for output in currentRoute.outputs {
            if output.portType == AVAudioSession.Port.builtInSpeaker {
                isSpeakerOutput = true
                break
            }
        }
        return isSpeakerOutput
    }

    /**
     * 打开扬声器外放
    */
    public func setSpeakerOn(_ on: Bool) {
        RTCAudioSession.sharedInstance().lockForConfiguration()
        do {
            if on {
                try RTCAudioSession.sharedInstance().setCategory(
                    AVAudioSession.Category.playAndRecord)
                try RTCAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
                try RTCAudioSession.sharedInstance().setActive(true)
            } else {
                try RTCAudioSession.sharedInstance().setCategory(
                    AVAudioSession.Category.playAndRecord)
                try RTCAudioSession.sharedInstance().overrideOutputAudioPort(.none)
            }
        } catch let error {
            debugPrint("Couldn't force audio to speaker: \(error)")
        }
        RTCAudioSession.sharedInstance().unlockForConfiguration()
    }

    /**
     * rtc音频外放是否禁止
    */
    public func isSpeakerMuted() -> Bool {
        return !self.factory.audioDeviceModule.playing
    }

    /**
     * 禁止/打开rtc音频外放
    */
    public func muteSpeaker(mute: Bool) {
        if mute {
            self.factory.audioDeviceModule.stopPlayout()
        } else {
            self.factory.audioDeviceModule.initPlayout()
            self.factory.audioDeviceModule.startPlayout()
        }
    }

    /**
     * rtc音频输入是否禁止
    */
    public func isMicrophoneMuted() -> Bool {
        return !self.factory.audioDeviceModule.recording
    }

    /**
     * 禁止/打开rtc音频输入
    */
    public func setMicrophoneMuted(_ mute: Bool) {
        if mute {
            self.factory.audioDeviceModule.stopRecording()
        } else {
            self.factory.audioDeviceModule.initRecording()
            self.factory.audioDeviceModule.startRecording()
        }
    }

    public func videoCaptureProxy(_ source: RTCVideoSource) -> RTCVideoCapturerDelegate? {
        self.videoCaptureDelegate?.videoSource = source
        return self.videoCaptureDelegate
    }

    public func clearVideoProxy() {
        self.videoCaptureDelegate?.videoSource = nil
    }

    public func updateVideoProxy(_ proxy: LiveVideoCapturerProxy?) {
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

    public func captureOriginAudio(_ samples: [[Float]], _ channel: Int) {
        DispatchQueue.main.async {
            var db: Float = 0.0
            for s in samples {
                db += Float(AudioUtils.calculateDecibel(from: s))
            }
            db = db / Float(channel)
            if db > 0 {
                for r in RTCRoomManager.shared.allRooms() {
                    _ = r.sendMyVolume(Double(db))
                }
            }
        }
    }
}
