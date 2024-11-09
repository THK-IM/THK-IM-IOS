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

    public var liveSignalProtocol: LiveSignalProtocol? = nil

    private init() {
        IMLiveRTCEngine.shared.initAudioSession()
    }

    func initUser(_ id: Int64, _ token: String, _ serverURL: String) {
        let liveApi = DefaultLiveApi(token: token, endpoint: serverURL)
        RTCRoomManager.shared.liveApi = liveApi
        RTCRoomManager.shared.myUId = id
    }

    public func onLiveSignalReceived(signal: LiveSignal) {
        guard let liveSignalProtocol = self.liveSignalProtocol else { return }
        liveSignalProtocol.onSignalReceived(signal)
    }
}
