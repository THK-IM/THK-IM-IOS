//
//  UIImageView+Cache.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/4.
//

import UIKit
import Kingfisher


public extension UIImageView {
    
    func ca_setImagePathWithCorner(path: String, radius: CGFloat) {
        self.layer.cornerRadius = radius
        self.clipsToBounds = true
        self.kf.setImage(with: LocalFileImageDataProvider(fileURL: URL(fileURLWithPath: path)))
    }
    
    func ca_setImageUrlWithCorner(url: String, radius: CGFloat) {
        self.layer.cornerRadius = radius
        self.clipsToBounds = true
        self.kf.setImage(with: URL(string: url))
    }
    
    func ca_setImagePath(path: String) {
        self.kf.setImage(with: LocalFileImageDataProvider(fileURL: URL(fileURLWithPath: path)))
    }
    
    
}
