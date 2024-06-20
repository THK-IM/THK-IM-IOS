//
//  ResourceUtils.swift
//  THK-IM-IOS
//
//  Created by viszoss on 2024/6/18.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit
import SVGKit


public class ResourceUtils {
    
    public static func iMUIBundle() -> Bundle {
        var bundleURL = Bundle.main.url(forResource: "Frameworks", withExtension: nil)
        bundleURL = bundleURL?.appendingPathComponent("THK_IM_IOS")
        bundleURL = bundleURL?.appendingPathExtension("framework")
        if (bundleURL == nil) {
            return Bundle.main
        }
        var bundle = Bundle.init(url: bundleURL!)
        if (bundle == nil) {
            return Bundle.main
        }
        bundleURL = bundle?.url(forResource: "IMUI", withExtension: "bundle")
        if (bundleURL == nil) {
            return Bundle.main
        }
        
        bundle = Bundle.init(url: bundleURL!)
        return bundle ?? Bundle.main
    }
    
    public static func loadImage(named: String, type: String = "svg", bundle: Bundle = iMUIBundle()) -> UIImage? {
        if (type == "svg") {
            if let path = bundle.path(forResource: named, ofType: type) {
                return SVGKImage(contentsOfFile: path)?.uiImage
            }
            if let path = Bundle.main.path(forResource: named, ofType: type) {
                return SVGKImage(contentsOfFile: path)?.uiImage
            }
        } else {
            if let path = bundle.path(forResource: named, ofType: type) {
                return UIImage(contentsOfFile: path)
            }
            if let path = Bundle.main.path(forResource: named, ofType: type) {
                return UIImage(contentsOfFile: path)
            }
        }
        return UIImage(named: named)
    }
    
    
    public static func loadString(_ key: String, tableName: String? = "IMUI", comment: String, bundle: Bundle = iMUIBundle()) -> String {
        let language = LanguageUtils.shared.userLanguage() ?? AppUtils.getLanguage()
        let subPath = bundle.path(forResource: language, ofType: ".lproj")
        if (subPath != nil) {
            let subBundle = Bundle.init(path: subPath!)
            let text = NSLocalizedString(key, tableName: tableName, bundle: subBundle!, comment: comment)
            return text
        } else {
            let text = NSLocalizedString(key, tableName: tableName, bundle: bundle, comment: comment)
            return text
        }
    }
    
    public static func loadStringFromMain(_ key: String, tableName: String? = nil, comment: String, bundle: Bundle = Bundle.main) -> String {
        let language = LanguageUtils.shared.userLanguage() ?? AppUtils.getLanguage()
        let subPath = bundle.path(forResource: language, ofType: ".lproj")
        if (subPath != nil) {
            let subBundle = Bundle.init(path: subPath!)
            let text = NSLocalizedString(key, tableName: tableName, bundle: subBundle!, comment: comment)
            return text
        } else {
            let text = NSLocalizedString(key, tableName: tableName, bundle: bundle, comment: comment)
            return text
        }
    }
    
    
}
