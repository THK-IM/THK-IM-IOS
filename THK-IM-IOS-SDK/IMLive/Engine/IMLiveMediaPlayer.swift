//
//  IMLiveMediaPlayer.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/10/30.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation
import AVFoundation

public class IMLiveMediaPlayer {
    
    static let shared = IMLiveMediaPlayer()
    
    private var bufferQueue = IMLiveCacheQueue<AVAudioPCMBuffer>()
    private let audioEngine = AVAudioEngine()
    private let audioPlayerNode = AVAudioPlayerNode()
    
    private var outputSettingsFormat: AVAudioFormat?
    private var isPlaying = false
    private let locker = NSLock()
    private var currentFramePos: UInt32 = 0
    private var avAudioPCMBuffer: AVAudioPCMBuffer?
    private var needPlayPCMBuffer = IMLiveCacheQueue<[Float]>()
    private var mediaPath = ""
    private var totalLenth: UInt32 = 0
    private var currentPos: UInt32 = 0
        
    private init() {}
    
    private func play(path: String) -> Bool {
        do {
            self.totalLenth = 0
            self.bufferQueue.clear()
            let inputFile = try AVAudioFile(forReading: path.asURL())
            guard let outputSettingsFormat = self.outputSettingsFormat else {
                return false
            }
            guard let sampleConverter = AVAudioConverter(from: inputFile.processingFormat, to: outputSettingsFormat) else {
                return false
            }
            let inFrameCount = inputFile.processingFormat.sampleRate
            let outFrameCount = UInt32(outputSettingsFormat.sampleRate)
            // 读取和转换音频数据
            let inputBuffer = AVAudioPCMBuffer(pcmFormat: inputFile.processingFormat, frameCapacity: UInt32(inFrameCount))!
            while(true) {
                // 读取输入音频数据
                try inputFile.read(into: inputBuffer)
                
                let inputBlock: AVAudioConverterInputBlock = { (inNumPackets, outStatus) -> AVAudioBuffer? in
                    outStatus.pointee = AVAudioConverterInputStatus.haveData
                    return inputBuffer
                }
                
                let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputSettingsFormat, frameCapacity: UInt32(outFrameCount))!
                var error: NSError?
                let status = sampleConverter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)

                // 处理出错情况
                if status == .error || error != nil {
                    self.bufferQueue.clear()
                    self.totalLenth = 0
                    return false
                }
                
                // 写入转换后的音频数据到输出文件
                if status != .error && error == nil {
                    if outputBuffer.frameLength > 0 {
                        self.totalLenth += outputBuffer.frameLength
                        self.bufferQueue.enqueue(outputBuffer)
                    }
                }
                
                // 结束循环
                if status == .endOfStream {
                    break
                }
                if inputBuffer.frameLength < Int(inFrameCount) {
                    break
                }
            }
            return true
        } catch {
            print(error)
            return false
        }
    }
    
    func setAudioFormat(_ channels: Int, _ sampleRate: Double) {
        let outputSettings = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: sampleRate,
            AVNumberOfChannelsKey: channels,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsNonInterleaved: false,
            AVLinearPCMIsFloatKey: true
        ] as [String : Any]
        self.outputSettingsFormat = AVAudioFormat.init(settings: outputSettings)
    }
    
    func sampleRate() -> Double {
        return self.outputSettingsFormat?.sampleRate ?? 1.0
    }
    
    func start(_ path: String) -> Bool {
        let success = self.play(path: path)
        if success {
            self.isPlaying = true
            self.mediaPath = path
        }
        return success
    }
    
    func pause() {
        self.isPlaying = false
    }
    
    func stop() {
        self.pause()
        self.mediaPath = ""
        bufferQueue.clear()
    }
    
    func fetchPcmBuffer(_ frameLength: UInt32) -> [Float]? {
        if (isPlaying) {
            if avAudioPCMBuffer == nil {
                avAudioPCMBuffer = bufferQueue.dequeue()
            }
            if avAudioPCMBuffer == nil {
                return nil
            }
            var data = [Float]()
            let remainLength = avAudioPCMBuffer!.frameLength - currentFramePos
            if remainLength >= frameLength {
                for i in 0 ..< frameLength {
                    data.append(avAudioPCMBuffer!.floatChannelData!.pointee[Int(i + currentFramePos)])
                }
                currentFramePos = currentFramePos + frameLength
            } else {
                for i in 0 ..< remainLength {
                    data.append(avAudioPCMBuffer!.floatChannelData!.pointee[Int(i + currentFramePos)])
                }
                currentFramePos = 0
                let needLength = frameLength - remainLength
                avAudioPCMBuffer = bufferQueue.dequeue()
                if avAudioPCMBuffer != nil  {
                    if (avAudioPCMBuffer!.frameLength >= needLength) {
                        for i in 0 ..< needLength {
                            data.append(avAudioPCMBuffer!.floatChannelData!.pointee[Int(i + currentFramePos)])
                        }
                        currentFramePos = needLength
                    }
                }
            }
            self.putCachedBuffer(data: data)
            return data
        }
        return nil
    }
    
    private func putCachedBuffer(data: [Float]) {
        locker.lock()
        defer {locker.unlock()}
        self.currentPos += UInt32(data.count)
        self.needPlayPCMBuffer.enqueue(data)
    }
    
    func cachedPCMBufffer() -> [Float]? {
        locker.lock()
        defer {locker.unlock()}
        return needPlayPCMBuffer.dequeue()
    }
}

