//
//  DefaultSignalModule.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/20.
//

import Foundation
import Starscream
import Alamofire
import CocoaLumberjack

public class DefaultSignalModule: SignalModule, WebSocketDelegate {
    
    
    private var token = ""
    private  var signalListener : SignalListener?
    private let reachabilityManager = NetworkReachabilityManager.init()
    private var status = SignalStatus.Init
    private var webSocketUrl = ""
    private var webSocketClient: WebSocket?
    private let connectTimeout = 5.0
    private let reconnectInterval: Float = 3.0
    private let heatBeatInterval = 10
    private let lock = NSLock.init()
    
    private var hearBeatTask: GCDTask?
    private var timeoutTask: GCDTask?
    private var reconnectTask: GCDTask?
    
    public init( _ token: String, _ webSocketUrl: String) {
        self.webSocketUrl = webSocketUrl
        self.token = token
    }
    
    public func connect() {
        DDLogDebug("DefaultSignalModule: connect start, status: \(self.status) ")
        lock.lock()
        defer {lock.unlock()}
        if self.status == SignalStatus.Connecting || self.status == SignalStatus.Connected {
            return
        }
        if self.webSocketClient != nil {
            self.webSocketClient?.forceDisconnect()
        }
        self.onStateChange(SignalStatus.Connecting)
        var request = URLRequest(url: URL(string: self.webSocketUrl)!)
        request.timeoutInterval = connectTimeout
        request.setValue(AppUtils.getDeviceName(), forHTTPHeaderField: APITokenInterceptor.deviceKey)
        request.setValue(AppUtils.getTimezone(), forHTTPHeaderField: APITokenInterceptor.timezoneKey)
        request.setValue(AppUtils.getVersion(), forHTTPHeaderField: APITokenInterceptor.versionKey)
        request.setValue(AppUtils.getLanguage(), forHTTPHeaderField: APITokenInterceptor.languageKey)
        request.setValue("IOS", forHTTPHeaderField: APITokenInterceptor.platformKey)
        request.setValue(token, forHTTPHeaderField: APITokenInterceptor.tokenKey)
        self.webSocketClient = WebSocket(request: request)
        self.webSocketClient?.delegate = self
        self.webSocketClient?.connect()
    }
    
    private func startTimeoutTask() {
        GCDTool.gcdCancel(self.timeoutTask)
        self.timeoutTask = GCDTool.gcdDelay(TimeInterval(connectTimeout)) { [weak self] in
            guard let sf = self else {
                return
            }
            DDLogDebug("DefaultSignalModule startTimeoutTask status \(sf.status)")
            if sf.status == SignalStatus.Connecting  {
                sf.onStateChange(SignalStatus.DisConnected)
            }
        }
    }
    
    private func cancelTimeoutTask() {
        GCDTool.gcdCancel(self.timeoutTask)
        self.timeoutTask = nil
    }
    
    private func startReconnectTask() {
        GCDTool.gcdCancel(self.reconnectTask)
        DDLogDebug("DefaultSignalModule startReconnectTask \(self.status)")
        self.reconnectTask = GCDTool.gcdDelay(TimeInterval(reconnectInterval)) { [weak self] in
            guard let sf = self else {
                return
            }
            sf.connect()
        }
    }
    
    private func cancelReconnectTask() {
        GCDTool.gcdCancel(self.reconnectTask)
        self.reconnectTask = nil
    }
    
    private func startHeatBeatTask() {
        GCDTool.gcdCancel(self.hearBeatTask)
        self.hearBeatTask = GCDTool.gcdDelay(TimeInterval(heatBeatInterval)) { [weak self] in
            guard let sf = self else {
                return
            }
            if sf.status == SignalStatus.Connected {
                sf.sendSignal(Signal.ping)
                sf.startHeatBeatTask()
            }
        }
    }
    
    private func cancelHeatBeatTask() {
        GCDTool.gcdCancel(self.hearBeatTask)
        self.hearBeatTask = nil
    }
    
    private func onTextMessage(_ message: String) {
        DispatchQueue.global().async { [weak self] in
            guard let sf = self else {
                return
            }
            DDLogDebug("DefaultSignalModule onTextMessage \(message)")
            var msg = message
            if let cipher = IMCoreManager.shared.crypto {
                msg = cipher.decrypt(message) ?? message
            }
            let signalData = msg.data(using: String.Encoding.utf8)
            if signalData != nil {
                do {
                    let signal = try JSONDecoder().decode(Signal.self, from: signalData!)
                    sf.lock.lock()
                    sf.signalListener?.onNewSignal(signal.type, signal.body)
                    sf.lock.unlock()
                } catch {
                    DDLogError("DefaultSignalModule onTextMessage error: \(error)")
                }
            }
        }
    }
    
    public func disconnect(_ reason: String) {
        lock.lock()
        self.webSocketClient?.forceDisconnect()
        self.signalListener = nil
        self.status = SignalStatus.DisConnected
        lock.unlock()
    }
    
    public func getSignalStatus() -> SignalStatus {
        lock.lock()
        defer { lock.unlock() }
        return self.status
    }
    
    public func setSignalListener(_ listener: SignalListener) {
        lock.lock()
        defer { lock.unlock() }
        self.signalListener = listener
    }
    
    
    public func sendSignal(_ signal: String) {
        lock.lock()
        defer { lock.unlock() }
        var msg = signal
        DDLogDebug("DefaultSignalModule sendSignal \(msg)")
        if let cipher = IMCoreManager.shared.crypto {
            msg = cipher.encrypt(signal) ?? signal
        }
        if self.status == SignalStatus.Connected {
            self.webSocketClient?.write(string: msg)
        }
    }
    
    
    public func didReceive(event: Starscream.WebSocketEvent, client: any Starscream.WebSocketClient) {
        switch event {
        case .connected:
            DDLogDebug("DefaultSignalModule: connected")
            onStateChange(SignalStatus.Connected)
            break
        case .disconnected:
            DDLogDebug("DefaultSignalModule: disconnected")
            onStateChange(SignalStatus.DisConnected)
            break
        case .text(let message):
            onTextMessage(message)
            break
        case .binary:
            DDLogDebug("DefaultSignalModule: binary")
            break
        case .ping(_):
            DDLogDebug("DefaultSignalModule: ping")
            break
        case .pong(_):
            DDLogDebug("DefaultSignalModule: pong")
            break
        case .viabilityChanged(let viability):
            DDLogDebug("DefaultSignalModule: viabilityChanged: \(viability)")
            if viability == false {
                onStateChange(SignalStatus.DisConnected)
            }
            break
        case .reconnectSuggested(_):
            DDLogDebug("DefaultSignalModule: reconnectSuggested")
            onStateChange(SignalStatus.DisConnected)
            break
        case .cancelled:
            DDLogDebug("DefaultSignalModule: cancelled")
            onStateChange(SignalStatus.DisConnected)
            break
        case .error(let error):
            DDLogDebug("DefaultSignalModule: error: \(error ?? CocoaError.error(.coderInvalidValue))")
            onStateChange(SignalStatus.DisConnected)
            break
        case .peerClosed:
            DDLogDebug("DefaultSignalModule: peerClosed")
            onStateChange(SignalStatus.DisConnected)
            break
        }
    }
    
    private func onStateChange(_ status: SignalStatus) {
        DDLogDebug("DefaultSignalModule: onStateChange \(status)")
        if (self.status != status) {
            self.status = status
            self.signalListener?.onSignalStatusChange(status)
            
            if (self.status == SignalStatus.Connecting) {
                // 连接中，只跑超时任务
                cancelHeatBeatTask()
                cancelReconnectTask()
                startTimeoutTask()
            } else if (self.status == SignalStatus.DisConnected) {
                // 连接断开，只跑重连任务
                cancelTimeoutTask()
                cancelHeatBeatTask()
                startReconnectTask()
            } else if (self.status == SignalStatus.Connected) {
                // 连接成功，只跑心跳任务
                cancelTimeoutTask()
                cancelReconnectTask()
                startHeatBeatTask()
            }
        }
    }
    
}
