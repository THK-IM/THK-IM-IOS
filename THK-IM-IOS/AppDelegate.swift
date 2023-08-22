//
//  AppDelegate.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/13.
//

import UIKit
import AliyunOSSiOS
import CocoaLumberjack
import GDPerformanceView_Swift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        initIM(application)
        return true
    }
    
    // MARK: UISceneSession Lifecycle
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func initIM(_ application: UIApplication) {
        IMUIManager.shared.registerBottomFunctionProvider(
            IMPhotoFunctionProvider(), IMCameraFunctionProvider()
        )
        IMUIManager.shared.registerEmojiControllerProvider(
            IMUnicodeEmojiControllerProvider(), IMUnicodeEmojiControllerProvider()
        )
        
//        IMManager.shared.initApplication(application, 1, true)
//        let ossBucket = "bucket"
//        let ossEndpoint = "https://"
//        let credentialProvider = OSSFederationCredentialProvider(federationTokenGetter: {
//            let token = OSSFederationToken()
//            token.tAccessKey = ""
//            token.tSecretKey =  ""
//            token.expirationTimeInGMTFormat = "2023-08-13T05:54:46Z"
//            token.tToken = ""
//            return token
//        })
//        IMManager.shared.fileLoadModule = DefaultFileLoadModule(ossBucket, ossEndpoint, credentialProvider)
        let debug = true
        IMCoreManager.shared.initApplication(application, 1, debug)
        IMCoreManager.shared.connect()
    }
    
    
}

