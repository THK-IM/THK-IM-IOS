//
//  IMLiveManager.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/2.

import AVFoundation
import CocoaLumberjack
import Foundation
import Moya
import RxSwift
import WebRTC

open class IMLiveManager {
    static let shared = IMLiveManager()
    public var liveApi: LiveApi {
        set {
            self._liveApi = newValue
        }
        get {
            return self._liveApi!
        }
    }
    public var liveSignalProtocol: LiveSignalProtocol? = nil
    
    private var disposeBag = DisposeBag()
    private var _liveApi: LiveApi? = nil
    private var room: RTCRoom?
    private var uId: Int64 = 0
    
    private init() {
        IMLiveRTCEngine.shared.initAudioSession()
    }
    
    public func setUId(uId: Int64) {
        self.uId = uId
    }
    
    public func setRoom(room: RTCRoom) {
        self.room = room
    }

    public func createRoom(mode: Mode, mediaParams: MediaParams) -> Observable<RTCRoom> {
        self.destroyRoom()
        let uId = selfId()
        let req = CreateRoomReqVo(
            uId: uId, mode: mode.rawValue, videoMaxBitrate: mediaParams.videoMaxBitrate,
            audioMaxBitrate: mediaParams.audioMaxBitrate, videoWidth: mediaParams.videoWidth,
            videoHeight: mediaParams.videoHeight, videoFps: mediaParams.videoFps
        )
        return self.liveApi.createRoom(req)
            .flatMap { [weak self] res -> Observable<RTCRoom> in
                let room = RTCRoom(
                    id: res.id, ownerId: res.ownerId, uId: uId, mode: mode.rawValue,
                    role: Role.Broadcaster.rawValue, createTime: res.createTime, mediaParams: res.mediaParams,
                    participants: res.participants
                )
                self?.room = room
                return Observable.just(room)
            }
    }
    
    public func callMembers(_ msg: String, _ duration: Int64, _ members: Set<Int64>) -> Observable<Void>? {
        guard let room = self.room else { return nil }
        let req = CallRoomMemberReqVo(uId: selfId(), roomId: room.id, msg: msg, duration: duration, members: members)
        return self.liveApi.callMembers(req)
    }

    public func joinRoom(roomId: String, role: Int) -> Observable<RTCRoom> {
        self.destroyRoom()
        let uId = selfId()
        return self.liveApi.joinRoom(JoinRoomReqVo(roomId: roomId, uId: uId, role: role))
            .flatMap { [weak self] res -> Observable<RTCRoom> in
                let room = RTCRoom(
                    id: res.id, ownerId: res.ownerId, uId: uId, mode: res.mode,
                    role: role, createTime: res.createTime, mediaParams: res.mediaParams,
                    participants: res.participants
                )
                self?.room = room
                return Observable.just(room)
            }
    }
    
    public func inviteMember(_ uIds: Set<Int64>, _ msg: String, _ duration: Int64) -> Observable<Void>? {
        guard let room = self.room else { return nil }
        let req = InviteMemberReqVo(uId: selfId(), roomId: room.id, msg: msg, duration: duration, inviteUIds: uIds)
        return self.liveApi.inviteMembers(req)
    }

    public func refuseJoinRoom(roomId: String, reason: String) {
        let uId = selfId()
        self.liveApi.refuseJoinRoom(RefuseJoinReqVo(roomId: roomId, uId: uId, msg: reason))
            .subscribe()
            .disposed(by: self.disposeBag)
    }
    
    public func kickoffMembers(roomId: String, reason: String, members: Set<Int64>) -> Observable<Void> {
        let req = KickoffMemberReqVo(uId: selfId(), roomId: roomId, msg: reason, kickoffUIds: members)
        return self.liveApi.kickoffMember(req)
    }
    
    public func leveaRoom() {
        let uId = selfId()
        guard let room = self.room else { return }
        if room.ownerId == uId {
            self.liveApi.deleteRoom(DelRoomReqVo(roomId: room.id, uId: uId))
                .subscribe()
                .disposed(by: self.disposeBag)
        }
        self.destroyRoom()
    }

    
    public func onLiveSignalReceived(signal: LiveSignal) {
        guard let delegate = self.liveSignalProtocol else { return }
        delegate.onSignalReceived(signal)
    }

    public func selfId() -> Int64 {
        return self.uId
    }

    public func getRoom() -> RTCRoom? {
        return room
    }
    
    public func destroyRoom() {
        self.disposeBag = DisposeBag()
        self.room?.destroy()
        self.room = nil
    }
}
