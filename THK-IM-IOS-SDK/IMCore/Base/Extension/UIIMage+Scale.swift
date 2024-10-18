//
//  UIIMage+Scale.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit

extension UIImage {

    public func scaledToSize(_ size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        let scaledImage = renderer.image { (context) in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
        return scaledImage
    }
}
