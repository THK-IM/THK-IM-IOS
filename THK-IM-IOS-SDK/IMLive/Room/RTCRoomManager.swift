//
//  RTCRoomManager.swift
//  THK-IM-IOS
//
//  Created by think on 2024/11/9.
//  Copyright © 2024 THK. All rights reserved.
//

import RxSwift

open class RTCRoomManager {
    static let shared = RTCRoomManager()

    public var liveApi: LiveApi {
        set {
            self._liveApi = newValue
        }
        get {
            return self._liveApi!
        }
    }

    private var disposeBag = DisposeBag()
    private var _liveApi: LiveApi? = nil
    private var room: RTCRoom?
    var myUId: Int64 = 0

    public func setRoom(room: RTCRoom) {
        self.room = room
    }

    public func currentRoom() -> RTCRoom? {
        return self.room
    }

    public func createRoom(mode: Mode, mediaParams: MediaParams) -> Observable<RTCRoom> {
        self.destroyRoom()
        let req = CreateRoomReqVo(
            uId: myUId, mode: mode.rawValue,
            videoMaxBitrate: mediaParams.videoMaxBitrate,
            audioMaxBitrate: mediaParams.audioMaxBitrate,
            videoWidth: mediaParams.videoWidth,
            videoHeight: mediaParams.videoHeight, videoFps: mediaParams.videoFps
        )
        return self.liveApi.createRoom(req)
            .flatMap { [weak self] res -> Observable<RTCRoom> in
                let room = RTCRoom(
                    id: res.id, ownerId: res.ownerId,
                    mode: mode.rawValue,
                    role: Role.Broadcaster.rawValue, createTime: res.createTime,
                    mediaParams: res.mediaParams,
                    participants: res.participants
                )
                self?.room = room
                return Observable.just(room)
            }
    }

    public func callRoomMembers(
        _ msg: String, _ duration: Int64, _ members: Set<Int64>
    ) -> Observable<Void>? {
        guard let room = self.room else { return nil }
        let req = CallRoomMemberReqVo(
            uId: myUId, roomId: room.id, msg: msg, duration: duration,
            members: members)
        return self.liveApi.callRoomMembers(req)
    }

    public func cancelCallRoomMembers(_ msg: String, _ members: Set<Int64>)
        -> Observable<Void>?
    {
        guard let room = self.room else { return nil }
        let req = CancelCallRoomMemberReqVo(
            uId: myUId, roomId: room.id, msg: msg, members: members)
        return self.liveApi.cancelCallRoomMembers(req)
    }

    public func joinRoom(roomId: String, role: Int) -> Observable<RTCRoom> {
        self.destroyRoom()
        return self.liveApi.joinRoom(
            JoinRoomReqVo(roomId: roomId, uId: myUId, role: role)
        )
        .flatMap { [weak self] res -> Observable<RTCRoom> in
            let room = RTCRoom(
                id: res.id, ownerId: res.ownerId, mode: res.mode,
                role: role, createTime: res.createTime,
                mediaParams: res.mediaParams,
                participants: res.participants
            )
            self?.room = room
            return Observable.just(room)
        }
    }

    public func inviteMember(
        _ uIds: Set<Int64>, _ msg: String, _ duration: Int64
    ) -> Observable<Void>? {
        guard let room = self.room else { return nil }
        let req = InviteMemberReqVo(
            uId: myUId, roomId: room.id, msg: msg, duration: duration,
            inviteUIds: uIds)
        return self.liveApi.inviteMembers(req)
    }

    public func refuseJoinRoom(roomId: String, reason: String) {
        self.liveApi.refuseJoinRoom(
            RefuseJoinReqVo(roomId: roomId, uId: myUId, msg: reason)
        )
        .subscribe()
        .disposed(by: self.disposeBag)
    }

    public func kickoffMembers(
        roomId: String, reason: String, members: Set<Int64>
    ) -> Observable<Void> {
        let req = KickoffMemberReqVo(
            uId: myUId, roomId: roomId, msg: reason, kickoffUIds: members)
        return self.liveApi.kickoffMember(req)
    }

    public func destroyRoom() {
        guard let room = self.room else { return }
        if room.ownerId == myUId {
            self.liveApi.deleteRoom(DelRoomReqVo(roomId: room.id, uId: myUId))
                .subscribe()
                .disposed(by: self.disposeBag)
        }
        self.leveaRoom()
    }

    public func leveaRoom() {
        self.disposeBag = DisposeBag()
        self.room?.destroy()
        self.room = nil
    }

}
