//
//  Data.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/10.
//

import Foundation

extension Data {
    
    func detectImageType() -> String {
        if self.count < 16 { return "" }
        
        var value = [UInt8](repeating:0, count:1)
        
        self.copyBytes(to: &value, count: 1)
        
        switch value[0] {
        case 0x4D, 0x49:
            return "tiff"
        case 0x00:
            return "ico"
        case 0x69:
            return "icns"
        case 0x47:
            return "gif"
        case 0x89:
            return "png"
        case 0xFF:
            return "jpeg"
        case 0x42:
            return "bmp"
        case 0x52:
            let subData = self.subdata(in: Range(NSMakeRange(0, 12))!)
            if let infoString = String(data: subData, encoding: .ascii) {
                if infoString.hasPrefix("RIFF") && infoString.hasSuffix("WEBP") {
                    return "webp"
                }
            }
            break
        default:
            break
        }
        return ""
    }
}
