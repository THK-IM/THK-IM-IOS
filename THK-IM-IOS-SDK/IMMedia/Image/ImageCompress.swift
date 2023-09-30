//
//  ImageCompressor.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/11.
//

import UIKit

public class ImageCompressor {
    
    // 压缩选项
    public class Options {
        var maxSize: Int64 = 100 * 1024 // 文件最大大小（单位：字节）
        var quality: CGFloat = 0.6       // 压缩质量（0~1）
        init(maxSize: Int64, quality: CGFloat) {
            self.maxSize = maxSize
            self.quality = quality
        }
    }
    
    // 压缩图片方法
    public static func compressImage(_ original: UIImage, _ options: Options) -> Data? {
        // 先缩小图片尺寸
        var resizedImage: UIImage? = nil
        var originData = original.pngData()
        if (originData == nil) {
            originData = original.jpegData(compressionQuality: 1.0)
        }
        if (originData == nil) {
            return nil
        }
        if originData!.count <= options.maxSize {
            return originData!
        }
        
        // 先按比例压缩
        let rate = sqrt(Double(originData!.count) / Double(options.maxSize)) * 2
        var sample = 2.0
        while (sample < rate) {
            sample *= 2
        }
        print("compress \(originData!.count) \(original.size) \(rate) \(sample)")
        let compressSize = CGSize(width: original.size.width / sample, height: original.size.height / sample)
        UIGraphicsBeginImageContextWithOptions(compressSize, false, UIScreen.main.scale)
        original.draw(in: CGRect(
            origin: .zero,
            size: compressSize))
        resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if resizedImage == nil {
            resizedImage = original
        }
        var resizeData = resizedImage!.pngData()
        if (resizeData == nil) {
            resizeData = resizedImage!.jpegData(compressionQuality: 1.0)
        }
        if (resizeData == nil) {
            return nil
        }
        // 如果大小不超过maxSize,返回
        if resizeData!.count <= options.maxSize {
            return resizeData!
        }
        
        // 如果是jpge图片，再压缩图片质量
        if resizedImage!.pngData() == nil {
            return resizeData!
        }
        return resizedImage!.jpegData(compressionQuality: options.quality)
    }
    
}


