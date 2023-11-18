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
    var fileLoadModule: FileLoadModule {
        set {
            self._fileLoadModule = newValue
        }
        get {
            return self._fileLoadModule!
        }
    }
    
    private var _storageModule: StorageModule?
    var storageModule: StorageModule {
        set {
            self._storageModule = newValue
        }
        get {
            return self._storageModule!
        }
    }
    
    private var _api: IMApi?
    var api: IMApi {
        set {
            self._api = newValue
        }
        get {
            return self._api!
        }
    }
    
    private var _signalModule: SignalModule?
    var signalModule: SignalModule {
        set {
            self._signalModule = newValue
        }
        get {
            return self._signalModule!
        }
    }
    
    
    private var _database: IMDatabase?
    var database : IMDatabase{
        set {
            self._database = newValue
        }
        get {
            return self._database!
        }
    }
    
    
    
    private var _uId: Int64? = nil
    var uId: Int64 {
        get {
            return self._uId!
        }
    }
    
    var severTime : Int64 {
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
    
    func initApplication(_ app : UIApplication, _ uId :Int64, _ debug: Bool) {
        self.initIMLog()
        self._uId = uId
        self._database = IMDatabase(app, uId, debug)
        self._storageModule = DefaultStorageModule(uId)
        
        self.registerModule(SignalType.User.rawValue, DefaultUserModule())
        self.registerModule(SignalType.Common.rawValue, DefaultCommonModule())
        self.registerModule(SignalType.Message.rawValue, DefaultMessageModule())
        
        getMessageModule().registerMsgProcessor(ReadMsgProcessor())
        getMessageModule().registerMsgProcessor(ReeditMsgProcessor())
        getMessageModule().registerMsgProcessor(RevokeMsgProcessor())
        
        do {
            try self._database?.messageDao.resetSendStatusFailed()
        } catch {
            DDLogError("initApplication: \(error)")
        }
    }
    
    public func connect() {
        self._signalModule?.setSignalListener(self)
        self._signalModule?.connect()
    }
    
    public func registerModule(_ type: Int, _ md: BaseModule) {
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
    
    func onSignalStatusChange(_ status: SignalStatus) {
        if (status == SignalStatus.Connected) {
            getMessageModule().syncOfflineMessages()
        }
        SwiftEventBus.post(IMEvent.OnlineStatusUpdate.rawValue, sender: status)
    }
    
    func onNewSignal(_ type: Int, _ subType: Int, _ body: String) {
        let module = getModule(type)
        module?.onSignalReceived(subType, body)
    }
    
}
