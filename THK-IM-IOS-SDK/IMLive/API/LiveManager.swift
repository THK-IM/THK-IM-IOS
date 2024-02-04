//
//  LiveManager.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/2.

import Foundation
import WebRTC
import RxSwift
import Moya
import CocoaLumberjack

class LiveManager {
    
    static let shared = LiveManager()
    
    private var _liveApi: LiveApi? = nil
    var liveApi: LiveApi {
        set {
            self._liveApi = newValue
        }
        get {
            return self._liveApi!
        }
    }
    
    private var room: Room?
    private var uId: Int64 = 0
    let factory:RTCPeerConnectionFactory
    private init() {
        RTCPeerConnectionFactory.initialize()
        let videoEncoderFactory = RTCDefaultVideoEncoderFactory()
        let videoDecoderFactory = RTCDefaultVideoDecoderFactory()
        self.factory = RTCPeerConnectionFactory.init(
            encoderFactory: videoEncoderFactory,
            decoderFactory: videoDecoderFactory
        )
        let audioSessionConfiguration = RTCAudioSessionConfiguration.webRTC()
        audioSessionConfiguration.category = "AVAudioSessionCategoryPlayAndRecord"
        audioSessionConfiguration.categoryOptions = [.defaultToSpeaker, .allowAirPlay, .allowBluetooth, .allowBluetoothA2DP]
        let webRTCSession = RTCAudioSession.sharedInstance()
        do {
            webRTCSession.lockForConfiguration()
            try webRTCSession.setConfiguration(audioSessionConfiguration, active: true)
            webRTCSession.unlockForConfiguration()
        } catch {
            DDLogError("setConfiguration \(error)")
        }
    }
    
    func setUId(uId: Int64) {
        self.uId = uId
    }
    
    func setLiveApi(api: LiveApi) {
        self._liveApi = api
    }
    
    func createRoom(mode: Mode) -> Observable<Room> {
        room?.destroy()
        let uId = selfId()
        return self.liveApi
            .createRoom(CreateRoomReqVo(uId: uId, mode: mode.rawValue))
            .flatMap{ resBean -> Observable<Room> in
                let room = Room(id: resBean.id, uId: uId, mode: mode, role: Role.Broadcaster, members: resBean.members)
                self.room = room
                return Observable.just(room)
            }
    }
    
    func joinRoom(roomId: String, role: Role, token: String) -> Observable<Room> {
        room?.destroy()
        let uId = selfId()
        return self.liveApi
            .joinRoom(JoinRoomReqVo(roomId: roomId, uId: uId, role: role.rawValue, token: token))
            .flatMap{ [weak self ] resBean -> Observable<Room> in
                guard let sf = self else {
                    return Observable.error(CocoaError.init(CocoaError.executableRuntimeMismatch))
                }
                var m = Mode.Chat
                if resBean.mode == Mode.Audio.rawValue {
                    m = Mode.Audio
                } else if resBean.mode == Mode.Video.rawValue {
                    m = Mode.Video
                }
                var members = [Member]()
                if resBean.members != nil {
                    for member in resBean.members! {
                        if (member.uId != sf.selfId()) {
                            members.append(member)
                        }
                    }
                }
                
                let room = Room(id: resBean.id, uId: uId, mode: m, role: role, members: members)
                sf.room = room
                return Observable.just(room)
            }
    }
    
    func selfId() -> Int64 {
        return self.uId
    }
    
    func getRoom() -> Room? {
        return room
    }
    
    func destroyRoom() {
        room?.destroy()
    }
    
}
