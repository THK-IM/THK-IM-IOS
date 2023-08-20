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
        var maxWidth: CGFloat = 1080.0   // 图片最大宽度
        var maxHeight: CGFloat = 1920.0  // 图片最大高度
        var maxSize: Int64 = 1024 * 1024 // 文件最大大小（单位：字节）
        var quality: CGFloat = 0.9       // 压缩质量（0~1）
        init(maxWidth: CGFloat, maxHeight: CGFloat, maxSize: Int64, quality: CGFloat) {
            self.maxWidth = maxWidth
            self.maxHeight = maxHeight
            self.maxSize = maxSize
            self.quality = quality
        }
    }
    
    // 压缩图片方法
    public static func compressImage(_ original: UIImage, _ options: Options) -> Data? {
        // 先缩小图片尺寸
        var size = original.size
        var resizedImage: UIImage? = nil
        if size.width > options.maxWidth || size.height > options.maxHeight {
            let ratio1 = options.maxWidth / size.width
            let ratio2 = options.maxHeight / size.height
            let ratio = min(ratio1, ratio2)
            size = CGSize(width: size.width * ratio, height: size.height * ratio)
            UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
            original.draw(in: CGRect(origin: .zero, size: size))
            resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        if resizedImage == nil {
            resizedImage = original
        }
        guard let resizeData = resizedImage!.pngData() else {
            return nil
        }
        if resizeData.count <= options.maxSize {
            return resizedImage!.pngData()
        }
        
        // 再压缩图片质量
        guard var compressedData = resizedImage!.jpegData(compressionQuality: options.quality) else {
            return resizedImage!.pngData()
        }
        if compressedData.count <= options.maxSize {
            return compressedData
        }
        
        // 如果文件大小超过限制，则进一步压缩尺寸
        guard var compressedImage = UIImage(data: compressedData) else {
            return compressedData
        }
        size = compressedImage.size
        while (compressedData.count > options.maxSize) {
            size = CGSize(width: size.width * 0.7, height: size.height * 0.7)
            UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
            compressedImage.draw(in: CGRect(origin: .zero, size: size))
            resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            if resizedImage == nil || resizedImage?.pngData() == nil {
                break
            } else {
                compressedImage = resizedImage!
                compressedData = (resizedImage?.pngData())!
            }
        }
        return compressedData
    }
    
}


