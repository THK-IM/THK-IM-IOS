//
//  IMLiveAudioCapturerProxy.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/10/30.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation
import WebRTC

// 音频录制重处理器
open class IMLiveAudioCapturerProxy: NSObject, RTCAudioCustomProcessingDelegate {

    private var lastCal: Int64 = 0

    open func audioProcessingInitialize(sampleRate sampleRateHz: Int, channels: Int) {
        IMLiveMediaPlayer.shared.setAudioFormat(channels, Double(sampleRateHz))
    }

    open func audioProcessingProcess(audioBuffer: RTCAudioBuffer) {
        //        let data = IMLiveMediaPlayer.shared.fetchPCMBuffer(UInt32(audioBuffer.frames))
        //        let sampleRate = IMLiveMediaPlayer.shared.sampleRate()
        //        for i in (0..<audioBuffer.channels) {
        //            let buffer = audioBuffer.rawBuffer(forChannel: i)
        //            var samples = [Float]()
        //            for i in 0..<audioBuffer.frames {
        //                if data != nil && data!.count > i {
        //                    buffer[i] = buffer[i] * 0.5 + data![i] * Float(sampleRate) * 0.5
        //                }
        //                samples.append(buffer[i])
        //            }
        //        }
        let current = Date().timeMilliStamp
        if current - self.lastCal > 500 {
            var channelBuffers = [[Float]]()
            for i in (0..<audioBuffer.channels) {
                let originBuffer = audioBuffer.rawBuffer(forChannel: i)
                let buffer = Array(
                    UnsafeBufferPointer(start: originBuffer, count: audioBuffer.frames))
                channelBuffers.append(buffer)
            }
            IMLiveRTCEngine.shared.captureOriginAudio(channelBuffers, audioBuffer.channels)
            self.lastCal = current
        }
    }

    open func audioProcessingRelease() {
        print("AudioCapturerProxy release")
    }

}
