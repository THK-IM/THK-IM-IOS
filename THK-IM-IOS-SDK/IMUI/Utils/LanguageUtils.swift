//
//  LanguageUtils.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/6/20.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

public class LanguageUtils: NSObject {
    
    public static let shared = LanguageUtils()
    
    private let UWUserLanguageKey = "UserLanguageKey"
    
    public func userLanguage() -> String? {
        return UserDefaults.standard.object(forKey: UWUserLanguageKey) as? String? ?? nil
    }
    
    public func initLanguage() {
        let language = self.userLanguage()
        if (language == nil) {
            UserDefaults.standard.setValue(nil, forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.setValue([language], forKey: "AppleLanguages")
        }
    }
    
    public func setUserLanguage(_ language: String?) -> Bool {
        UserDefaults.standard.setValue(language, forKey: UWUserLanguageKey)
        if (language == nil) {
            UserDefaults.standard.setValue(nil, forKey: "AppleLanguages")
        } else {
            UserDefaults.standard.setValue([language], forKey: "AppleLanguages")
        }
        return UserDefaults.standard.synchronize()
    }
    
    
}
