//
//  SVGImageUtils.swift
//  THK-IM-IOS
//
//  Created by viszoss on 2024/6/18.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit
import SVGKit


public class SVGImageUtils {
    
    public static func loadSVG(named: String, bundleName: String = "IMUI") -> UIImage? {
        if let image = UIImage(named: named) {
            return image
        }
        if let path = Bundle.main.path(forResource: named, ofType: "svg") {
            return SVGKImage(contentsOfFile: path)?.uiImage
        }
        var bundleURL = Bundle.main.url(forResource: "Frameworks", withExtension: nil)
        bundleURL = bundleURL?.appendingPathComponent("THK_IM_IOS")
        bundleURL = bundleURL?.appendingPathExtension("framework")
        if (bundleURL == nil) {
            return nil
        }
        var bundle = Bundle.init(url: bundleURL!)
        if (bundle == nil) {
            return nil
        }
        bundleURL = bundle?.url(forResource: bundleName, withExtension: "bundle")
        if (bundleURL == nil) {
            return nil
        }
        bundle = Bundle.init(url: bundleURL!)
        if (bundle == nil) {
            return nil
        }
        guard let path = bundle!.path(forResource: named, ofType: "svg") else {
            return nil
        }
        return SVGKImage(contentsOfFile: path)?.uiImage
    }
    
}
