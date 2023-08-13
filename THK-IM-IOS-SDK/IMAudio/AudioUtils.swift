//
//  AudioUtils.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/13.
//

import Foundation
import AVFoundation
import Accelerate

func calculateDecibel(from data: Data) -> Float {
    guard let int16Array = getInt16Array(from: data) else { return -1 }
    let sum = int16Array.reduce(0, { $0 + Int($1) })
    let averagePower = Float(sum) / Float(int16Array.count)
    let dB = 20 * log10(abs(averagePower) / 1.0)
    return dB
}

func getInt16Array(from data: Data) -> [Int16]? {
    let count = data.count / MemoryLayout<Int16>.size
    var int16Array = [Int16](repeating: 0, count: count)
    (data as NSData).getBytes(&int16Array, length:count * MemoryLayout<Int16>.size)
    return int16Array
}
