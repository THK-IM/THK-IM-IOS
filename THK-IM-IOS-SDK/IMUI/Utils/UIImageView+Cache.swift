//
//  UIImageView+Cache.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/4.
//

import Kingfisher
import UIKit

extension UIImageView {

    public func renderImageByPathWithCorner(
        path: String, radius: CGFloat, placeHolderImage: UIImage? = nil
    ) {
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
        self.kf.setImage(
            with: LocalFileImageDataProvider(fileURL: URL(fileURLWithPath: path)),
            placeholder: placeHolderImage)
    }

    public func renderImageByUrlWithCorner(
        url: String, radius: CGFloat, placeHolderImage: UIImage? = nil
    ) {
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
        self.kf.setImage(with: URL(string: url), placeholder: placeHolderImage)
    }

    public func renderImageByUrl(url: String, placeHolderImage: UIImage? = nil) {
        self.layer.masksToBounds = true
        self.kf.setImage(with: URL(string: url), placeholder: placeHolderImage)
    }
    
    public func renderImageByUrl(url: String, processor: ImageProcessor, placeHolderImage: UIImage? = nil) {
        self.layer.masksToBounds = true
        self.kf.setImage(with: URL(string: url), placeholder: placeHolderImage, options: [
            .processor(processor),
            .scaleFactor(UIScreen.main.scale),
            .cacheOriginalImage
        ])
    }

    public func renderImageByUrl(
        url: String, placeHolderImage: UIImage? = nil,
        _ completeHandler: ((Result<RetrieveImageResult, KingfisherError>) -> Void)? = nil
    ) {
        self.layer.masksToBounds = true
        self.kf.setImage(
            with: URL(string: url), placeholder: placeHolderImage,
            completionHandler: completeHandler)
    }

    public func renderImageByPath(path: String, placeHolderImage: UIImage? = nil) {
        self.layer.masksToBounds = true
        self.kf.setImage(
            with: LocalFileImageDataProvider(fileURL: URL(fileURLWithPath: path)),
            placeholder: placeHolderImage)
    }

    public func renderImageByPath(path: String, radius: CGFloat, placeHolderImage: UIImage? = nil) {
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
        self.kf.setImage(
            with: LocalFileImageDataProvider(fileURL: URL(fileURLWithPath: path)),
            placeholder: placeHolderImage)
    }

}
