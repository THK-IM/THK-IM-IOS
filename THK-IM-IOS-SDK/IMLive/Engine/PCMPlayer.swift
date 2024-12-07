//
//  PCMPlayer.swift
//  THK-IM-IOS
//
//  Created by think on 2024/12/7.
//  Copyright © 2024 THK. All rights reserved.
//

import AVFoundation

class PCMPlayer {
    private var audioEngine: AVAudioEngine!
    private var playerNode: AVAudioPlayerNode!
    private var audioFormat: AVAudioFormat!

    init(sampleRate: Double, channels: UInt32) {
        // 初始化音频引擎和播放器节点
        audioEngine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()

        // 定义音频格式
        audioFormat = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: channels
        )

        // 连接播放器节点到主混音器
        audioEngine.attach(playerNode)
        audioEngine.connect(
            playerNode, to: audioEngine.mainMixerNode, format: audioFormat)
    }

    func start() {
        do {
            // 启动音频引擎
            try audioEngine.start()
            playerNode.play()
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }

    func stop() {
        playerNode.stop()
        audioEngine.stop()
    }

    func playPCMData(_ pcmData: Data) {
        let buffer = AVAudioPCMBuffer(
            pcmFormat: audioFormat,
            frameCapacity: UInt32(pcmData.count)
                / audioFormat.streamDescription.pointee.mBytesPerFrame
        )!

        buffer.frameLength = buffer.frameCapacity

        pcmData.withUnsafeBytes { bytes in
            guard let baseAddress = bytes.baseAddress else { return }
            memcpy(
                buffer.audioBufferList.pointee.mBuffers.mData, baseAddress,
                pcmData.count)
        }

        playerNode.scheduleBuffer(buffer, completionHandler: nil)
    }

    func playPCMData(_ pcmData: [Float]) {
        // 创建 AVAudioPCMBuffer
        let frameCount = UInt32(pcmData.count) / audioFormat.channelCount
        guard
            let buffer = AVAudioPCMBuffer(
                pcmFormat: audioFormat,
                frameCapacity: frameCount
            )
        else {
            print("Failed to create AVAudioPCMBuffer")
            return
        }

        buffer.frameLength = frameCount

        // 将浮点数组数据复制到缓冲区
        let channelCount = Int(audioFormat.channelCount)
        for channel in 0..<channelCount {
            if let channelData = buffer.floatChannelData?[channel] {
                for frame in 0..<Int(frameCount) {
                    channelData[frame] = pcmData[frame * channelCount + channel]
                }
            }
        }

        // 调度缓冲区进行播放
        playerNode.scheduleBuffer(buffer, completionHandler: nil)
    }
}
