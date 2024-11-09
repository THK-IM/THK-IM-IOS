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
    public var myUId: Int64 = 0

    private var disposeBag = DisposeBag()
    private var _liveApi: LiveApi? = nil
    
    private var rtcRooms = [RTCRoom]()

    public func allRooms() -> [RTCRoom] {
        return self.rtcRooms
    }

    public func addRoom(_ room: RTCRoom) {
        self.rtcRooms.append(room)
    }

    public func getRoomById(_ id: String) -> RTCRoom? {
        return self.rtcRooms.first { r in
            r.id == id
        }
    }

    public func createRoom(mode: Mode, mediaParams: MediaParams) -> Observable<RTCRoom> {
        let req = CreateRoomReqVo(
            uId: myUId, mode: mode.rawValue,
            videoMaxBitrate: mediaParams.videoMaxBitrate,
            audioMaxBitrate: mediaParams.audioMaxBitrate,
            videoWidth: mediaParams.videoWidth,
            videoHeight: mediaParams.videoHeight, videoFps: mediaParams.videoFps
        )
        return self.liveApi.createRoom(req)
            .flatMap { res -> Observable<RTCRoom> in
                let room = RTCRoom(
                    id: res.id, ownerId: res.ownerId,
                    mode: mode.rawValue,
                    role: Role.Broadcaster.rawValue, createTime: res.createTime,
                    mediaParams: res.mediaParams,
                    participants: res.participants
                )
                return Observable.just(room)
            }
    }
    
    public func joinRoom(roomId: String, role: Int) -> Observable<RTCRoom> {
        return self.liveApi.joinRoom(
            JoinRoomReqVo(roomId: roomId, uId: myUId, role: role)
        )
        .flatMap { res -> Observable<RTCRoom> in
            let room = RTCRoom(
                id: res.id, ownerId: res.ownerId, mode: res.mode,
                role: role, createTime: res.createTime,
                mediaParams: res.mediaParams,
                participants: res.participants
            )
            return Observable.just(room)
        }
    }

    public func callRoomMembers(
        _ id: String, _ msg: String, _ duration: Int64, _ members: Set<Int64>
    ) {
        let req = CallRoomMemberReqVo(
            uId: myUId, roomId: id, msg: msg, duration: duration,
            members: members)
        self.liveApi.callRoomMembers(req)
            .compose(RxTransformer.shared.io2Main())
            .subscribe().disposed(by: self.disposeBag)
    }

    public func cancelCallRoomMembers(_ id: String, _ msg: String, _ members: Set<Int64>) {
        let req = CancelCallRoomMemberReqVo(
            uId: myUId, roomId: id, msg: msg, members: members)
        self.liveApi.cancelCallRoomMembers(req)
            .compose(RxTransformer.shared.io2Main())
            .subscribe().disposed(by: self.disposeBag)
    }

    public func inviteNewMembers( _ id: String,
        _ uIds: Set<Int64>, _ msg: String, _ duration: Int64
    ) {
        let req = InviteMemberReqVo(
            uId: myUId, roomId: id, msg: msg, duration: duration,
            inviteUIds: uIds)
        self.liveApi.inviteMembers(req)
            .compose(RxTransformer.shared.io2Main())
            .subscribe().disposed(by: self.disposeBag)
    }

    public func refuseJoinRoom(roomId: String, reason: String) {
        let req = RefuseJoinReqVo(roomId: roomId, uId: myUId, msg: reason)
        self.liveApi.refuseJoinRoom(req)
        .compose(RxTransformer.shared.io2Main())
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

    /**
     * 离开房间, 如果是房主，在删除房间
     */
    func leaveRoom(id: String, delRoom: Bool) {
        guard let room = self.getRoomById(id) else { return }
        if (room.ownerId == myUId && delRoom) {
            self.liveApi.delRoom(DelRoomVo(id, myUId)).compose(RxTransform.flowableToMain())
                .subscribe(subscriber)
            disposes.add(subscriber)
        }
        rtcRooms.removeAll {
            it.id == id
        }
    }

}
