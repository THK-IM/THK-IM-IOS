//
//  ImageCacheManager.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/26.
//

import Foundation
import Kingfisher

public class ImageCacheManager: NSObject {
    
    public static let shared = ImageCacheManager()
    
    private override init() {
        ImageCache.default.memoryStorage.config.totalCostLimit = 100 * 1024 * 1024
        ImageCache.default.memoryStorage.config.countLimit = 100
        ImageCache.default.memoryStorage.config.keepWhenEnteringBackground = false
        ImageCache.default.diskStorage.config.expiration = .days(30)
        ImageCache.default.diskStorage.config.sizeLimit = 2 * 1024 * 1024 * 1024
    }
}
