//
//  AppDelegate.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/13.
//

import UIKit
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
        let debug = true
        let uId : Int64 = 15498
        let token = String(uId)
        let apiEndpoint = "http://api.thkim.com"
        let wsEndpoint = "ws://ws.thkim.com/ws"
        IMCoreManager.shared.initApplication(application, uId, debug)
        IMCoreManager.shared.api = DefaultIMApi(endpoint: apiEndpoint)
        IMCoreManager.shared.signalModule = DefaultSignalModule(application, wsEndpoint, "\(uId)")
        
        IMCoreManager.shared.fileLoadModule = DefaultFileLoadModule("\(uId)", apiEndpoint)
        IMUIManager.shared.initConfig()
        IMUIManager.shared.contentProvider = Provider(token: token)
        IMUIManager.shared.contentPreviewer = Previewer(token: token)
        IMCoreManager.shared.connect()
        
    }
    
    
}

