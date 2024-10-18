//
//  UIColor+HexString.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/4.
//

import UIKit

extension UIColor {

    /// 通过16进制的字符串创建UIColor
    ///
    /// - Parameter hex: 16进制字符串，格式为#ececec
    public convenience init(hex: String, factor: UInt64 = 1) {
        let r: CGFloat
        let g: CGFloat
        let b: CGFloat
        let a: CGFloat
        var start: String.Index
        if hex.hasPrefix("#") {
            start = hex.index(hex.startIndex, offsetBy: 1)
        } else {
            start = hex.index(hex.startIndex, offsetBy: 0)
        }
        let hexColor = String(hex[start...])
        if hexColor.count == 8 {
            let scanner = Scanner(string: hexColor)
            var hexNumber: UInt64 = 0
            if scanner.scanHexInt64(&hexNumber) {
                hexNumber = UInt64(hexNumber / factor)
                a = CGFloat((hexNumber & 0xff00_0000) >> 24) / 255
                r = CGFloat((hexNumber & 0x00ff_0000) >> 16) / 255
                g = CGFloat((hexNumber & 0x0000_ff00) >> 8) / 255
                b = CGFloat((hexNumber & 0x0000_00ff) >> 0) / 255
                self.init(red: r, green: g, blue: b, alpha: a)
                return
            }
        } else if hexColor.count == 6 {
            let scanner = Scanner(string: hexColor)
            var hexNumber: UInt64 = 0
            if scanner.scanHexInt64(&hexNumber) {
                hexNumber = UInt64(hexNumber / factor)
                r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                b = CGFloat((hexNumber & 0x0000ff)) / 255
                a = 1.0
                self.init(red: r, green: g, blue: b, alpha: a)
                return
            }
        }
        self.init(red: 256, green: 256, blue: 256, alpha: 256)
    }

    /// 将UIColor转换为16进制字符串。
    public func toHexString() -> String {
        let components = self.cgColor.components
        let r: CGFloat = components?[0] ?? 0.0
        let g: CGFloat = components?[1] ?? 0.0
        let b: CGFloat = components?[2] ?? 0.0

        let hexString = String(
            format: "#%02lX%02lX%02lX", lroundf(Float(r * 255)), lroundf(Float(g * 255)),
            lroundf(Float(b * 255)))
        return hexString
    }
}
