//
//  IMCoreManager.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/13.
//

import Foundation
import CocoaLumberjack
import RxSwift

open class IMCoreManager: SignalListener {
    
    public static let shared = IMCoreManager()
    
    private var moduleDic = [Int: BaseModule]()
    private var disposeBag = DisposeBag()
    
    private var _fileLoadModule: FileLoadModule?
    public var fileLoadModule: FileLoadModule {
        set {
            self._fileLoadModule = newValue
        }
        get {
            return self._fileLoadModule!
        }
    }
    
    private var _storageModule: StorageModule?
    public var storageModule: StorageModule {
        set {
            self._storageModule = newValue
        }
        get {
            return self._storageModule!
        }
    }
    
    private var _api: IMApi?
    public var api: IMApi {
        set {
            self._api = newValue
        }
        get {
            return self._api!
        }
    }
    
    private var _signalModule: SignalModule?
    public var signalModule: SignalModule {
        set {
            self._signalModule = newValue
        }
        get {
            return self._signalModule!
        }
    }
    
    
    private var _database: IMDatabase?
    public var database : IMDatabase{
        set {
            self._database = newValue
        }
        get {
            return self._database!
        }
    }
    
    
    
    private var _uId: Int64? = nil
    public var uId: Int64 {
        get {
            return self._uId!
        }
    }
    
    public var severTime : Int64 {
        get {
            return self.getCommonModule().getSeverTime()
        }
    }
    
    private init() {}
    
    private func initIMLog() {
        DDLog.add(DDOSLogger.sharedInstance) // Uses os_log
        let fileLogger: DDFileLogger = DDFileLogger() // File Logger
        fileLogger.rollingFrequency = 60 * 60 * 24 // 24 hours
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        DDLog.add(fileLogger)
    }
    
    public func initApplication(_ app : UIApplication, _ uId :Int64, _ debug: Bool) {
        self.initIMLog()
        self._uId = uId
        self._database = DefaultIMDatabase(app, uId, debug)
        self._storageModule = DefaultStorageModule(uId)
        
        self.registerModule(SignalType.User.rawValue, DefaultUserModule())
        self.registerModule(SignalType.Common.rawValue, DefaultCommonModule())
        self.registerModule(SignalType.Message.rawValue, DefaultMessageModule())
        
        getMessageModule().registerMsgProcessor(IMReadMsgProcessor())
    }
    
    public func connect() {
        self.database.open()
        self._signalModule?.setSignalListener(self)
        self._signalModule?.connect()
    }
    
    public func registerModule(_ type: Int, _ md: BaseModule) {
        moduleDic[type] = md
    }
    
    public func getModule(_ type: Int) -> BaseModule? {
        return moduleDic[type]
    }
    
    public func getCommonModule() -> CommonModule {
        return self.getModule(SignalType.Common.rawValue)! as! CommonModule
    }
    
    public func getUserModule() -> UserModule {
        return self.getModule(SignalType.User.rawValue)! as! UserModule
    }
    
    public func getContactModule() -> ContactModule {
        return self.getModule(SignalType.Contact.rawValue)! as! ContactModule
    }
    
    public func getGroupModule() -> GroupModule {
        return self.getModule(SignalType.Group.rawValue)! as! GroupModule
    }
    
    public func getMessageModule() -> MessageModule {
        return self.getModule(SignalType.Message.rawValue)! as! MessageModule
    }
    
    public func getCustomModule() -> CustomModule {
        return self.getModule(SignalType.Custom.rawValue)! as! CustomModule
    }
    
    public func onSignalStatusChange(_ status: SignalStatus) {
        if (status == SignalStatus.Connected) {
            getMessageModule().syncOfflineMessages()
        }
        SwiftEventBus.post(IMEvent.OnlineStatusUpdate.rawValue, sender: status)
    }
    
    public func onNewSignal(_ type: Int, _ subType: Int, _ body: String) {
        let module = getModule(type)
        module?.onSignalReceived(subType, body)
    }
    
}
