//
//  IMLiveRTCEngine.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/10/30.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation
import WebRTC
import CocoaLumberjack

public class IMLiveRTCEngine: NSObject {

    public static let shared = IMLiveRTCEngine()

    var factory: RTCPeerConnectionFactory
    private var audioProccessingMoudle: RTCDefaultAudioProcessingModule
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
        module.renderPreProcessingDelegate = audioRenderDelegate
        self.audioProccessingMoudle = module
        
        let videoProxy = IMLiveVideoCapturerProxy()
        self.videoCaptureDelegate = videoProxy
        
        
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        self.factory = RTCPeerConnectionFactory.init(
            bypassVoiceProcessing: true,
            encoderFactory: videoEncoderFactory,
            decoderFactory: videoDecoderFactory,
            audioProcessingModule: module
        )

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
        self.audioProccessingMoudle.capturePostProcessingDelegate = delegate
    }

    public func updateAudioRenderDelegate(_ delegate: RTCAudioCustomProcessingDelegate) {
        self.audioRenderDelegate = delegate
        self.audioProccessingMoudle.renderPreProcessingDelegate = delegate
    }

    public func onAudioCapture(_ samples: [Float], _ channel: Int) {
        let db = AudioUtils.calculateDecibel(from: samples)
        guard let room = IMLiveManager.shared.getRoom() else { return }
        room.sendMyVolume(db)
    }
}
