//
//  AudioUtils.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/13.
//

import Foundation
import AVFoundation
import Accelerate

public func calculateDecibel(from data: Data) -> Double {
    // 将 PCM 数据转换为 Int16 数组
    let samples = data.withUnsafeBytes {
        Array(UnsafeBufferPointer<Int16>(start: $0.baseAddress!.assumingMemoryBound(to: Int16.self), count: data.count/MemoryLayout<Int16>.size))
    }
    
    var totalAmplitude: Int64 = 0
    let numSamples = samples.count
    
    for sample in samples {
        totalAmplitude += Int64(abs(sample))
    }
    
    let averageAmplitude = Double(totalAmplitude) / Double(numSamples)
    if averageAmplitude < 0 {
        return 0.0
    }
    return 20 * log10(averageAmplitude)
}

public func getInt8Array(from data: Data) -> [Int8]? {
    let count = data.count / MemoryLayout<Int8>.size
    var int8Array = [Int8](repeating: 0, count: count)
    (data as NSData).getBytes(&int8Array, length:count * MemoryLayout<Int8>.size)
    return int8Array
}
