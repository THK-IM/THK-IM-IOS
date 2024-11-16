//
//  LiveManager.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/2.

import AVFoundation
import CocoaLumberjack
import Foundation
import Moya
import RxSwift
import WebRTC

open class LiveManager {

    static let shared = LiveManager()

    public var liveRequestProcessor: LiveRequestProcessor? = nil

    private init() {
        IMLiveRTCEngine.shared.initAudioSession()
    }

    func initUser(_ id: Int64, _ token: String, _ serverURL: String) {
        let liveApi = DefaultLiveApi(token: token, endpoint: serverURL)
        RTCRoomManager.shared.liveApi = liveApi
        RTCRoomManager.shared.myUId = id
    }

    public func onLiveSignalReceived(signal: LiveSignal) {
        if signal.type == LiveSignalType.BeingRequested.rawValue {
            if let request = signal.signalForType(
                LiveSignalType.BeingRequested.rawValue,
                BeingRequestedSignal.self)
            {
                self.liveRequestProcessor?.onBeingRequested(signal: request)
            }
        } else if signal.type == LiveSignalType.CancelBeingRequested.rawValue {
            if let request = signal.signalForType(
                LiveSignalType.CancelBeingRequested.rawValue,
                CancelBeingRequestedSignal.self)
            {
                self.liveRequestProcessor?.onCancelBeingRequested(
                    signal: request)
            }
        }
        SwiftEventBus.post(liveSignalEvent, sender: signal)
    }
}
