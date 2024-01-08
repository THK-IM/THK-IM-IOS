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
    
    var commonModule: CommonModule
    var userModule: UserModule
    var contactModule: ContactModule
    var groupModule: GroupModule
    var messageModule: MessageModule
    var customModule: CustomModule
    
    private init() {
        self.commonModule = DefaultCommonModule()
        self.userModule = DefaultUserModule()
        self.contactModule = DefaultContactModule()
        self.groupModule = DefaultGroupModule()
        self.messageModule = DefaultMessageModule()
        self.customModule = DefaultCustomModule()
    }
    
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
        
        getMessageModule().registerMsgProcessor(IMReadMsgProcessor())
    }
    
    public func connect() {
        self.database.open()
        self._signalModule?.setSignalListener(self)
        self._signalModule?.connect()
    }
    
    public func getCommonModule() -> CommonModule {
        return self.commonModule
    }
    
    public func getUserModule() -> UserModule {
        return self.userModule
    }
    
    public func getContactModule() -> ContactModule {
        return self.contactModule
    }
    
    public func getGroupModule() -> GroupModule {
        return self.groupModule
    }
    
    public func getMessageModule() -> MessageModule {
        return self.messageModule
    }
    
    public func getCustomModule() -> CustomModule {
        return self.customModule
    }
    
    public func onSignalStatusChange(_ status: SignalStatus) {
        if (status == SignalStatus.Connected) {
            getMessageModule().syncOfflineMessages()
            getContactModule().syncContacts()
            getMessageModule().syncLatestSessionsFromServer()
        }
        SwiftEventBus.post(IMEvent.OnlineStatusUpdate.rawValue, sender: status)
    }
    
    public func onNewSignal(_ type: Int, _ body: String) {
        if (type == SignalType.SignalNewMessage.rawValue) {
            messageModule.onSignalReceived(type, body)
        } else if (type < 100) {
            commonModule.onSignalReceived(type, body)
        } else if (type < 200) {
            userModule.onSignalReceived(type, body)
        } else if (type < 300) {
            contactModule.onSignalReceived(type, body)
        } else if (type < 400) {
            groupModule.onSignalReceived(type, body)
        } else {
            customModule.onSignalReceived(type, body)
        }
    }
    
}
