//
//  LiveAudioCapturerProxy.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/10/30.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation
import WebRTC

// 音频录制重处理器
open class LiveAudioCapturerProxy: NSObject, RTCAudioCustomProcessingDelegate {

    private var lastCal: Int64 = 0
    private var sampleRate = 1

    open func audioProcessingInitialize(sampleRate sampleRateHz: Int, channels: Int) {
        print("LiveAudioCapturerProxy initialize: sampleRate \(sampleRateHz), channels \(channels)")
        self.sampleRate = sampleRateHz
        LiveMediaPlayer.shared.setAudioFormat(channels, Double(sampleRateHz))
    }

    open func audioProcessingProcess(audioBuffer: RTCAudioBuffer) {
//        let current = Date().timeMilliStamp
//        if current - self.lastCal > 500 {
//            // ex: 480 audioBuffer.frames 3 audioBuffer.bands 160 audioBuffer.framesPerBand
//            var channelBuffers = [[Float]]()
//            for i in (0..<audioBuffer.channels) {
//                let originBuffer = audioBuffer.rawBuffer(forChannel: i)
//                let buffer = Array(
//                    UnsafeBufferPointer(start: originBuffer, count: min(audioBuffer.frames, 256))
//                )
//                channelBuffers.append(buffer)
//            }
//            LiveRTCEngine.shared.captureOriginAudio(channelBuffers, audioBuffer.channels)
//            self.lastCal = current
//        }
        print("LiveAudioCapturerProxy sampleRate \(audioBuffer.frames), channels \(audioBuffer.channels), framesPerBand \(audioBuffer.framesPerBand), bands \(audioBuffer.bands)")
        let data = LiveMediaPlayer.shared.fetchPCMBuffer(UInt32(audioBuffer.frames))
        for i in  (0..<audioBuffer.channels) {
            if (data != nil) {
                let buffer = audioBuffer.rawBuffer(forChannel: i)
                let count = min(data!.count, audioBuffer.frames)
                for i in 0 ..< count {
                    buffer[i] = buffer[i] * 0.5 + data![i] * Float(sampleRate) * 0.5
                }
            }
        }
    }

    open func audioProcessingRelease() {
        print("AudioCapturerProxy release")
    }

}
