//
//  UIImageView+Cache.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/4.
//

import UIKit
import Kingfisher


public extension UIImageView {
    
    func renderImageByPathWithCorner(path: String, radius: CGFloat, placeHolderImage: UIImage? = nil) {
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
        self.kf.setImage(with: LocalFileImageDataProvider(fileURL: URL(fileURLWithPath: path)), placeholder: placeHolderImage)
    }
    
    func renderImageByUrlWithCorner(url: String, radius: CGFloat, placeHolderImage: UIImage? = nil) {
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
        self.kf.setImage(with: URL(string: url), placeholder: placeHolderImage)
    }
    
    func renderImageByUrl(url: String, placeHolderImage: UIImage? = nil) {
        self.kf.setImage(with: URL(string: url), placeholder: placeHolderImage)
    }
    
    func renderImageByUrl(url: String, placeHolderImage: UIImage? = nil, _ completeHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil) {
        self.kf.setImage(with: URL(string: url), placeholder: placeHolderImage, completionHandler: completeHandler)
    }
    
    func renderImageByPath(path: String, placeHolderImage: UIImage? = nil) {
        self.kf.setImage(with: LocalFileImageDataProvider(fileURL: URL(fileURLWithPath: path)), placeholder: placeHolderImage)
    }
    
    func renderImageByPath(path: String, radius: CGFloat, placeHolderImage: UIImage? = nil) {
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
        self.kf.setImage(with: LocalFileImageDataProvider(fileURL: URL(fileURLWithPath: path)), placeholder: placeHolderImage)
    }
    
}
