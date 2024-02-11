//
//  IMLiveManager.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/2.

import Foundation
import WebRTC
import RxSwift
import Moya
import CocoaLumberjack

class IMLiveManager {
    
    static let shared = IMLiveManager()
    
    private let disposeBag = DisposeBag()
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
    
    func setRoom(room: Room) {
        self.room = room
    }
    
    func createRoom(ids: Set<Int64>, mode: Mode) -> Observable<Room> {
        room?.destroy()
        let uId = selfId()
        return self.liveApi.createRoom(CreateRoomReqVo(uId: uId, mode: mode.rawValue, members: ids))
            .flatMap{ resVo -> Observable<Room> in
                let room = Room(
                    id: resVo.id, ownerId: resVo.ownerId, uId: uId, mode: mode, members: resVo.members,
                    role: Role.Broadcaster, createTime: resVo.createTime, participants: resVo.participants
                )
                self.room = room
                return Observable.just(room)
            }
    }
    
    func joinRoom(roomId: String, role: Role) -> Observable<Room> {
        room?.destroy()
        let uId = selfId()
        return self.liveApi.joinRoom(JoinRoomReqVo(roomId: roomId, uId: uId, role: role.rawValue))
            .flatMap{ [weak self ] resVo -> Observable<Room> in
                guard let sf = self else {
                    return Observable.error(CocoaError.init(CocoaError.executableRuntimeMismatch))
                }
                var m = Mode.Chat
                if resVo.mode == Mode.Audio.rawValue {
                    m = Mode.Audio
                } else if resVo.mode == Mode.Video.rawValue {
                    m = Mode.Video
                }
                var participants = [ParticipantVo]()
                if resVo.participants != nil {
                    for p in resVo.participants! {
                        if (p.uId != sf.selfId()) {
                            participants.append(p)
                        }
                    }
                }
                let room = Room(
                    id: resVo.id, ownerId: resVo.ownerId, uId: uId, mode: m, members: resVo.members,
                    role: Role.Broadcaster, createTime: resVo.createTime, participants: resVo.participants
                )
                sf.room = room
                return Observable.just(room)
            }
    }
    
    func leaveRoom() {
        let uId = selfId()
        if let room = self.room  {
            if uId == room.ownerId {
                self.liveApi.deleteRoom(DelRoomReqVo(roomId: room.id, uId: uId))
                    .subscribe(onError: { [weak self] _ in
                        self?.destroyRoom()
                    } , onCompleted: { [weak self] in
                        self?.destroyRoom()
                    }).disposed(by: self.disposeBag)
            } else {
                self.liveApi.refuseJoinRoom(RefuseJoinReqVo(roomId: room.id, uId: uId))
                    .subscribe(onError: { [weak self] _ in
                        self?.destroyRoom()
                    } , onCompleted: { [weak self] in
                        self?.destroyRoom()
                    }).disposed(by: self.disposeBag)
            }
        }
    }
    
    func onMemberHangup(roomId: String, uId: Int64) {
        if let room = self.room {
            if room.id == roomId {
                room.onMemberHangup(uId: uId)
            }
        }
    }
    
    func onEndCall(roomId: String) {
        if let room = self.room {
            room.onCallEnd()
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
        room = nil
    }
}
