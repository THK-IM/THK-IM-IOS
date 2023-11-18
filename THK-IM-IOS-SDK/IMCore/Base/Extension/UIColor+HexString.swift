//
//  UIColor+HexString.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/4.
//

import UIKit


public extension UIColor {
    
    /// 通过16进制的字符串创建UIColor
    ///
    /// - Parameter hex: 16进制字符串，格式为#ececec
    convenience init (hex: String) {
        let hex = (hex as NSString).trimmingCharacters(in: .whitespacesAndNewlines)
        let scanner = Scanner(string: hex)
        
        if hex.hasPrefix("#") {
            scanner.currentIndex = hex.startIndex
        }
        
        var color: UInt64 = 0
        scanner.scanHexInt64(&color)
        
        let mask = 0x000000FF
        let r = Int(color >> 16) & mask
        let g = Int(color >> 8) & mask
        let b = Int(color) & mask
        
        let red   = CGFloat(r) / 255.0
        let green = CGFloat(g) / 255.0
        let blue  = CGFloat(b) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }
 
    
    /// 将UIColor转换为16进制字符串。
    func toHexString() -> String {
        let components = self.cgColor.components
        let r: CGFloat = components?[0] ?? 0.0
        let g: CGFloat = components?[1] ?? 0.0
        let b: CGFloat = components?[2] ?? 0.0
 
        let hexString = String(format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)), lroundf(Float(b * 255)))
        return hexString
    }
}
 
