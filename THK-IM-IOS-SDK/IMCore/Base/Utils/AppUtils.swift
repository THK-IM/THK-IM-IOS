//
//  AppUtils.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/18.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import AVFoundation
import CocoaLumberjack
import AdSupport

public class AppUtils {
    
    private static var language = Locale.current.languageCode ?? "Unknown"
    
    public static func newMessageNotify() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord)
            let isSilentMode = audioSession.secondaryAudioShouldBeSilencedHint
            if isSilentMode {
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
            } else {
                let systemSoundID: SystemSoundID = 1007
                AudioServicesPlaySystemSound(systemSoundID)
            }
        }
        catch {
            DDLogError("\(error)")
        }
    }
    
    public static func getWindow() -> UIWindow? {
        if #available(iOS 13.0, *) {
            return UIApplication.shared.windows.first
        } else {
            return UIApplication.shared.keyWindow
        }
    }
    
    public static func getStatusBarHeight() -> CGFloat {
        if #available(iOS 13.0, *) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                let statusBarHeight = windowScene.statusBarManager?.statusBarFrame.height ?? 0
                return statusBarHeight
            }
        } else {
            return UIApplication.shared.statusBarFrame.height
        }
        return 0
    }
    
    public static func getVersion() -> String {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        return appVersion ?? "0.0.0"
    }
    
    public static func getTimezone() -> String {
        return "GMT+\(TimeZone.current.secondsFromGMT()/3600)"
    }
    
    public static func getDeviceName() -> String {
        return UIDevice.current.name
    }
    
    public static func getLanguage() -> String {
        return language
    }
    
    public static func setLanguage(language: String) {
        AppUtils.language = language
    }
    
    public static func getAdvertisingId() -> String? {
        if ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
            return ASIdentifierManager.shared().advertisingIdentifier.uuidString
        } else {
            return nil
        }
    }
    
}
