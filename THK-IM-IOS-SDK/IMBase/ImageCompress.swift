//
//  ImageCompressor.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/11.
//

import ImageIO
import MobileCoreServices
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
        
        // 按比例压缩
        let rate = sqrt(Double(originData!.count) / Double(options.maxSize)) * 2
        var sample = 2.0
        while (sample < rate) {
            sample *= 2
        }
        var width: Int64 = Int64(original.size.width / sample)
        var height: Int64 = Int64(original.size.height / sample)
        if (width % 2 != 0) {
            width += 1
        }
        if (height % 2 != 0) {
            height += 1
        }
        let compressSize = CGSize(width: Double(width), height: Double(height))
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
    
    public static func compressImageFile(_ srcPath: String, _ desPath: String, _ options: Options) throws {
        guard let srcData = FileManager.default.contents(atPath: srcPath) else {
            throw CocoaError.init(.fileNoSuchFile)
        }
        guard let image = UIImage(data: srcData) else {
            throw CocoaError.init(.fileReadCorruptFile)
        }
        if srcData.detectImageType() == "gif" {
            let srcExist = FileManager.default.fileExists(atPath: desPath)
            if srcExist {
                throw CocoaError.error(.fileWriteFileExists)
            }
            let success = FileManager.default.createFile(atPath: desPath, contents: nil)
            if (!success) {
                throw CocoaError(.fileWriteUnknown)
            }
            let inputURL = URL.init(fileURLWithPath: srcPath)
            let outputURL = URL.init(fileURLWithPath: desPath)
            let width = CGFloat(image.size.width) * (CGFloat(options.maxSize) / CGFloat(srcData.count))
            try compressGIF(inputURL: inputURL, outputURL: outputURL, quality: options.quality, width: width)
            return
        } else {
            let compressData = compressImage(image, options)
            let srcExist = FileManager.default.fileExists(atPath: desPath)
            if srcExist {
                throw CocoaError.error(.fileWriteFileExists)
            }
            
            let success = FileManager.default.createFile(atPath: desPath, contents: compressData)
            if (!success) {
                throw CocoaError(.fileWriteUnknown)
            }
        }
    }

    public static func compressGIF(inputURL: URL, outputURL: URL, quality: CGFloat, width: CGFloat) throws {
        guard let source = CGImageSourceCreateWithURL(inputURL as CFURL, nil) else {
            throw CocoaError.error(.fileNoSuchFile)
        }
        guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, kUTTypeGIF, CGImageSourceGetCount(source), nil) else {
            throw CocoaError.error(.fileWriteFileExists)
        }
        
        let frameCount = CGImageSourceGetCount(source)
        let minWidth: Double = 100.0
        var interval = 1
        var newWidth = width
        if (newWidth < minWidth) {
            interval = Int(sqrt((minWidth/newWidth)))
            newWidth = minWidth
        }
        print("compressGIF \(interval) \(newWidth)")
        let options: NSDictionary = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: newWidth,
            kCGImageDestinationLossyCompressionQuality: quality
        ]
        
        for index in 0..<frameCount {
            if (index % interval != 0) {
                continue
            }
            guard let image = CGImageSourceCreateThumbnailAtIndex(source, index, options) else {
                continue
            }
            let frameProperties: NSDictionary = [
                kCGImagePropertyGIFDictionary: [
                    kCGImagePropertyGIFDelayTime:  0.1
                ]
            ]
            CGImageDestinationAddImage(destination, image, frameProperties)
        }
        
        CGImageDestinationFinalize(destination)
    }
    
}


