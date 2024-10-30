//
//  IMLiveAudioRenderProxy.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/10/30.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation
import WebRTC

// 音频播放重处理器
open class IMLiveAudioRenderProxy: NSObject, RTCAudioCustomProcessingDelegate {
    

    open func audioProcessingInitialize(sampleRate sampleRateHz: Int, channels: Int) {
        
    }

    open func audioProcessingProcess(audioBuffer: RTCAudioBuffer) {
        let data = IMLiveMediaPlayer.shared.cachedPCMBufffer()
        let sampleRate = IMLiveMediaPlayer.shared.sampleRate()
        for i in (0..<audioBuffer.channels) {
            if (data != nil) {
                let buffer = audioBuffer.rawBuffer(forChannel: i)
                for i in 0..<audioBuffer.frames {
                    if data != nil && data!.count > i {
                        buffer[i] = buffer[i] * 0.5 + data![i] * Float(sampleRate) * 0.5
                    }
                }
            }
        }
    }

    open func audioProcessingRelease() {
        print("AudioRenderProxy release")
    }

    
}

