//
//  AudioUtils.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/13.
//

import AVFoundation
import Accelerate
import Foundation

public class AudioUtils {

    public static func calculateDecibel(from data: Data) -> Double {
        if data.isEmpty {
            return 0.0
        }
        // 将 PCM 数据转换为 Int16 数组
        let samples = data.withUnsafeBytes {
            Array(
                UnsafeBufferPointer<Int16>(
                    start: $0.baseAddress!.assumingMemoryBound(to: Int16.self),
                    count: data.count / MemoryLayout<Int16>.size))
        }

        var totalAmplitude: Int64 = 0
        let numSamples = samples.count
        if numSamples == 0 {
            return 0.0
        }

        for sample in samples {
            totalAmplitude += Int64(abs(sample))
        }

        let averageAmplitude = Double(totalAmplitude) / Double(numSamples)
        if averageAmplitude <= 0 {
            return 0.0
        }
        return 20 * log10(averageAmplitude)
    }

    public static func calculateDecibel(from samples: [Float]) -> Double {
        var totalAmplitude: Double = 0
        let numSamples = samples.count
        if numSamples == 0 {
            return 0.0
        }

        for sample in samples {
            totalAmplitude += Double(abs(sample))
        }

        let averageAmplitude = Double(totalAmplitude) / Double(numSamples)
        if averageAmplitude <= 0 {
            return 0.0
        }
        return 20 * log10(averageAmplitude)
    }

    public static func getInt8Array(from data: Data) -> [Int8]? {
        let count = data.count / MemoryLayout<Int8>.size
        var int8Array = [Int8](repeating: 0, count: count)
        (data as NSData).getBytes(&int8Array, length: count * MemoryLayout<Int8>.size)
        return int8Array
    }

//    public static func calculateRMS2(_ data: [Float]) -> Float {
//        var sum: Float = 0.0
//        for i in 0..<data.count {
//            sum += data[i] * data[i]
//        }
//        let rms = sqrt(sum / Float(data.count))
//        return 20 * log10(rms)
//    }
    
}
