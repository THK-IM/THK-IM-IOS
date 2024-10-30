//
//  IMLiveVideoCapturerProxy.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/10/30.
//  Copyright © 2024 THK. All rights reserved.
//

import AVFoundation
import CoreImage
import Foundation
import WebRTC

open class IMLiveVideoCapturerProxy: NSObject, RTCVideoCapturerDelegate {

    public var videoSource: RTCVideoSource?

    open func capturer(_ capturer: RTCVideoCapturer, didCapture frame: RTCVideoFrame) {
        let originTimestampNs = frame.timeStampNs
        let start = Date().timeMilliStamp
        if let pixelBuffer = self.convertI420ToPixelBuffer(frame: frame) {
            let processedBuffer = self.processCVPixelBuffer(pixelBuffer)
            let end = Date().timeMilliStamp
            if processedBuffer != nil {
                let timestampNs = originTimestampNs + (end - start) * 1_000_000
                let rtcCVPixelBuffer = RTCCVPixelBuffer(pixelBuffer: processedBuffer!)
                let newFrame = RTCVideoFrame(
                    buffer: rtcCVPixelBuffer, rotation: frame.rotation, timeStampNs: timestampNs)
                self.videoSource?.capturer(capturer, didCapture: newFrame)
            } else {
                self.videoSource?.capturer(capturer, didCapture: frame)
            }
        } else {
            self.videoSource?.capturer(capturer, didCapture: frame)
        }
    }

    open func convertI420ToPixelBuffer(frame: RTCVideoFrame) -> CVPixelBuffer? {
        let rtcPixelBuffer = frame.buffer as? RTCCVPixelBuffer
        let pixelBuffer = rtcPixelBuffer?.pixelBuffer
        return pixelBuffer
    }

    open func processCVPixelBuffer(_ pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        return nil
    }
}
