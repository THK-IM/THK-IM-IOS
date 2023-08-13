//
//  IMManager.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/13.
//

import Foundation
import CocoaLumberjack
import RxSwift
import Kingfisher
import SwiftEventBus

class IMManager: SignalListener {
    
    static let shared = IMManager()
    static let ApiEndpoint = "http://192.168.1.4:18000"
    static let WsEndpoint = "ws://192.168.1.4:18002"
    
    private var moduleDic = [Int: BaseModule]()
    private var disposeBag = DisposeBag()
    
    var fileLoadModule :FileLoaderModule?
    var storageModule: StorageModule?
    
    private var _database: IMDatabase?
    var database : IMDatabase{
        set {
            self._database = newValue
        }
        get {
            return self._database!
        }
    }
    
    var uId: Int64 {
        get {
            return self._uId!
        }
    }
    
    private var _uId: Int64? = nil
    
    var severTime : Int64 {
        get {
            return self.getCommonModule().getSeverTime()
        }
    }
    
    private var _signalModule: SignalModule?
    private var signalModule: SignalModule {
        get {
            return self._signalModule!
        }
    }
    
    private init() {
    }
    
    func initApplication(_ app : UIApplication, _ uId :Int64, _ debug: Bool) {
        DDLog.add(DDOSLogger.sharedInstance) // Uses os_log
        let fileLogger: DDFileLogger = DDFileLogger() // File Logger
        fileLogger.rollingFrequency = 60 * 60 * 24 // 24 hours
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        DDLog.add(fileLogger)
        let wsUrl = String(format: "%@/ws", IMManager.WsEndpoint)
        self._uId = uId
        self._database = IMDatabase(app, uId, debug)
        
        do {
            try self._database?.messageDao.resetSendingMsg(MsgStatus.SendFailed.rawValue)
        } catch {
            DDLogError("initApplication: \(error)")
        }
        
        self._signalModule = DefaultSignalModule(app, wsUrl, String(uId))
        self.registerModule(SignalType.User.rawValue, DefaultUserModule())
        self.registerModule(SignalType.Common.rawValue, DefaultCommonModule())
        self.registerModule(SignalType.Message.rawValue, DefaultMessageModule())
        
        self.getMessageModule().registerMsgProcessor(TextMsgProcessor())
        self.getMessageModule().registerMsgProcessor(ImageMsgProcessor())
        self.getMessageModule().registerMsgProcessor(AudioMsgProcessor())
        self.getMessageModule().registerMsgProcessor(VideoMsgProcessor())
        
        // Limit memory cache size to 300 MB.
        ImageCache.default.memoryStorage.config.totalCostLimit = 20 * 1024 * 1024
        
        // Limit memory cache to hold 150 images at most.
        ImageCache.default.memoryStorage.config.countLimit = 10
        storageModule = DefaultStorageModule(uId)
    }
    
    func connect() {
        self._signalModule?.setSignalListener(self)
        self._signalModule?.connect()
    }
    
    func registerModule(_ type: Int, _ md: BaseModule) {
        moduleDic[type] = md
    }
    
    func getModule(_ type: Int) -> BaseModule? {
        return moduleDic[type]
    }
    
    func getCommonModule() -> CommonModule {
        return self.getModule(SignalType.Common.rawValue)! as! CommonModule
    }
    
    func getUserModule() -> UserModule {
        return self.getModule(SignalType.User.rawValue)! as! UserModule
    }
    
    func getContactorModule() -> ContactModule {
        return self.getModule(SignalType.Contact.rawValue)! as! ContactModule
    }
    
    func getGroupModule() -> GroupModule {
        return self.getModule(SignalType.Group.rawValue)! as! GroupModule
    }
    
    func getMessageModule() -> MessageModule {
        return self.getModule(SignalType.Message.rawValue)! as! MessageModule
    }
    
    func getCustomModule() -> CustomModule {
        return self.getModule(SignalType.Custom.rawValue)! as! CustomModule
    }
    
    func onStatusChange(_ status: ConnectStatus) {
        if (status == ConnectStatus.Connected) {
            let lastSyncTime = getMessageModule().getOfflineMsgLastSyncTime()
            getMessageModule().syncOfflineMessages(lastSyncTime, 0, 500)
        }
        SwiftEventBus.post(IMEvent.OnlineStatusUpdate.rawValue, sender: status)
    }
    
    func onNewMessage(_ type: Int, _ subType: Int, _ body: String) {
        let module = getModule(type)
        module?.onSignalReceived(subType, body)
    }
    
}
