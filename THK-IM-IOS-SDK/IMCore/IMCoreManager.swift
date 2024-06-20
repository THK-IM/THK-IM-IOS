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
    public var env = "Debug"
    public static let shared = IMCoreManager()
    private var debug = false
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
    
    public var uId: Int64 = 0
    
    public var severTime : Int64 {
        get {
            return commonModule.getSeverTime()
        }
    }
    
    public var commonModule: CommonModule
    public var userModule: UserModule
    public var contactModule: ContactModule
    public var groupModule: GroupModule
    public var messageModule: MessageModule
    public var customModule: CustomModule
    
    public var crypto: Crypto?
    
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
    
    public func initApplication(_ debug: Bool = true) {
        self.debug = debug
        if self.debug {
            self.env = "Release"
        }
        self.initIMLog()
    }
    
    public func initUser(_ uId :Int64) {
        if (uId < 0) {
            return
        }
        if (self.uId == uId) {
            return
        }
        
        if (self.uId != 0) {
            self.shutDown()
        }
        
        self.uId = uId
        self._database = DefaultIMDatabase(uId, debug)
        self.database.open()
        self._storageModule = DefaultStorageModule(uId)
        self.connect()
    }
    
    private func connect() {
        self._signalModule?.setSignalListener(self)
        self._signalModule?.connect()
    }
    
    public func onSignalStatusChange(_ status: SignalStatus) {
        if (status == SignalStatus.Connected) {
            messageModule.syncLatestSessionsFromServer()
            messageModule.syncOfflineMessages()
            contactModule.syncContacts()
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
    
    public func shutDown() {
        fileLoadModule.reset()
        messageModule.reset()
        signalModule.disconnect("showdown")
        _database?.close()
        self.uId = 0
    }
    
}
