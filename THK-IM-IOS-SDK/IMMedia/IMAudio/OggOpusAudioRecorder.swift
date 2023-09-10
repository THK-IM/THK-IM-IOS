//
//  OpusAudioRecorder.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/16.
//

import AVFoundation
import CocoaLumberjack

typealias AudioCallback = (_ db: Double, _ duration: Int, _ path: String, _ stopped: Bool) -> Void

class OggOpusAudioRecorder {
    
    private let LogTag = "OggOpusAudioRecorder"
    static let shared = OggOpusAudioRecorder()
    
    private let callbackInterval = 200 // 单位ms
    private var _callback : AudioCallback?
    private var _filePath : String?
    private var _fileHandle: FileHandle?
    private var _startTimestamp: Int64?
    private var _maxDuration: Int?
    private var _oggEncoder : OGGEncoder?
    
    
    private var lastCallbackTime = Date().timeMilliStamp
    // 定义一个 AudioQueueRef 对象
    private var _audioQueue: AudioQueueRef?
    // 定义一个 AudioStreamBasicDescription 对象
    private var _audioFormat = AudioStreamBasicDescription()
    
    private let lock = NSLock()
    
    private init() {
        // 配置录音格式 48KHz双声道
        _audioFormat.mSampleRate = 16000
        _audioFormat.mFormatID = kAudioFormatLinearPCM
        _audioFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked
        _audioFormat.mBitsPerChannel = 16
        _audioFormat.mChannelsPerFrame = 1
        _audioFormat.mFramesPerPacket = 1
        _audioFormat.mBytesPerFrame = _audioFormat.mChannelsPerFrame * (_audioFormat.mBitsPerChannel / 8)
        _audioFormat.mBytesPerPacket = _audioFormat.mBytesPerFrame * _audioFormat.mFramesPerPacket
        _audioFormat.mReserved = 0
    }
    
    func startRecording(
        _ filePath: String,
        _ maxDuration: Int = 60,
        _ callback: @escaping AudioCallback
    ) -> Bool {
        if maxDuration <= 0 {
            return false
        }
        if (self.isRecording()) {
            return false
        }
        if (self.initAudioQueue(filePath)) {
            self._maxDuration = maxDuration
            self._filePath = filePath
            self._callback = callback
            return true
        } else {
            self.stopRecording()
            return false
        }
    }
    
    func isRecording() -> Bool  {
        return self._audioQueue != nil
    }
    
    // 停止录音
    func stopRecording() {
        DispatchQueue.global().async { [weak self] in
            self?.releaseAudioQueue()
        }
    }
    
    // 录音回调函数
    private let audioInputCallback: AudioQueueInputCallback = { (inUserData, inAQ, inBuffer, _, _, _) in
        if inBuffer.pointee.mAudioDataByteSize == 0 {
            return
        }
        defer {
            // 重新排队缓冲区
            AudioQueueEnqueueBuffer(inAQ, inBuffer, 0, nil)
        }
        guard let userData = inUserData else {
            return
        }
        let recorder = Unmanaged<OggOpusAudioRecorder>.fromOpaque(userData).takeUnretainedValue()
        let audioPCMData = NSData(
            bytes: inBuffer.pointee.mAudioData,
            length: Int(inBuffer.pointee.mAudioDataByteSize)
        )
        recorder.processPCMData(audioPCMData as Data)
    }
    
    private func initAudioQueue(_ filePath: String) -> Bool {
        lock.lock()
        defer {lock.unlock()}
        if AVAudioSession.sharedInstance().recordPermission == .denied {
            return false
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playAndRecord,
                options: [.defaultToSpeaker, .allowAirPlay, .allowBluetooth, .allowBluetoothA2DP])
            try AVAudioSession.sharedInstance().setActive(true)
            
            let existed = FileManager.default.fileExists(atPath: filePath)
            if existed {
                try FileManager.default.removeItem(atPath: filePath)
            }
            let success = FileManager.default.createFile(atPath: filePath, contents: nil)
            if !success {
                DDLogError("[\(LogTag)] audio file create error \(filePath)")
                return false
            }
            self._fileHandle = FileHandle(forWritingAtPath: filePath)
            if (self._fileHandle == nil) {
                DDLogError("[\(LogTag)] audio fileHandler create error \(filePath)")
                return false
            }
            
            let encoderAudioFormat = AVAudioFormat(streamDescription: &_audioFormat)
            // opus 编码器
            if (encoderAudioFormat == nil) {
                DDLogError("[\(LogTag)] encoderAudioFormat error")
                return false
            }
            self._oggEncoder = try OGGEncoder(
                format: _audioFormat,
                opusRate: Int32(_audioFormat.mSampleRate),
                application: .audio
            )
        } catch {
            DDLogError("[\(LogTag)] opusEncoder init error \(error)")
            return false
        }
        
        
        // 创建录音队列
        var status = AudioQueueNewInput(
            &_audioFormat,
            audioInputCallback,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            nil,
            nil,
            0,
            &_audioQueue
        )
        if status != noErr {
            DDLogError("[\(LogTag)] Error creating audio queue: \(status)")
            return false
        }
        
        // 准备录音队列缓冲区
        for _ in 0..<1 {
            var bufferRef : AudioQueueBufferRef? = nil
            status = AudioQueueAllocateBuffer(
                _audioQueue!,
                _audioFormat.mBytesPerPacket * UInt32((_audioFormat.mSampleRate/10)),
                &bufferRef)
            
            if status != noErr || bufferRef == nil  {
                DDLogError("[\(LogTag)] Error enqueueing audio alloc buffer: \(status)")
                return false
            }
            
            status = AudioQueueEnqueueBuffer(_audioQueue!, bufferRef!, 0, nil)
            if status != noErr {
                DDLogError("[\(LogTag)] Error enqueueing audio queue buffer: \(status)")
                return false
            }
        }
        
        // 打开录音队列
        status = AudioQueueStart(_audioQueue!, nil)
        if status != noErr {
            DDLogError("[\(LogTag)] starting audio queue: \(status)")
            return false
        }
        return true
    }
    
    private func releaseAudioQueue() {
        sleep(1) // 停止前等待写入缓冲
        if (_audioQueue != nil) {
            let status = AudioQueueStop(_audioQueue!, true)
            if status == noErr {
                // 释放录音队列
                _ = AudioQueueDispose(_audioQueue!, true)
            }
        }
        _audioQueue = nil
        sleep(1) // 停止后等缓冲写入文件
        stopped()
    }
    
    private func processPCMData(_ audioPCMData: Data) {
        if (!isRecording()) {
            return
        }
        lock.lock()
        if (_startTimestamp == nil) {
            _startTimestamp = Date().timeMilliStamp
        }
        let now = Date().timeMilliStamp
        if (_callback != nil && _filePath != nil) {
            if (now - lastCallbackTime) > callbackInterval {
                // 计算分贝并回调
                let db = calculateDecibel(from: audioPCMData)
                self._callback!(db, Int(now - _startTimestamp!), _filePath!, false)
                lastCallbackTime = now
            }
        }
        do {
            try _oggEncoder?.encode(pcm: audioPCMData)
        } catch {
            DDLogError("[\(LogTag)] error: \(error)")
        }
        lock.unlock()
        if (_startTimestamp != nil && _maxDuration != nil) {
            if (now - _startTimestamp! >= _maxDuration! * 1000) {
                stopRecording()
            }
        }
    }
    
    private func stopped() {
        lock.lock()
        defer {lock.unlock()}
        if (_oggEncoder != nil && _fileHandle != nil) {
            let oggData = self._oggEncoder!.bitstream()
            _fileHandle!.write(oggData)
            do {
                try _fileHandle!.close()
                if self._callback != nil && self._filePath != nil {
                    let now = Date().timeMilliStamp
                    self._callback!(0, Int(now - (self._startTimestamp ?? now)), self._filePath!, true)
                }
            } catch {
                DDLogError("[\(LogTag)] error: \(error)")
            }
        }
        _oggEncoder = nil
        _callback = nil
        _filePath = nil
        _startTimestamp = nil
        _fileHandle = nil
        _maxDuration = nil
    }
    
}
