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

    /**
    * 创建房间
    */
    public func createRoom(mode: RoomMode, mediaParams: MediaParams)
        -> Observable<RTCRoom>
    {
        let req = CreateRoomReqVo(
            uId: myUId, mode: mode.rawValue,
            mediaParams: .H43_H1080
        )
        return self.liveApi.createRoom(req)
            .flatMap { res -> Observable<RTCRoom> in
                let room = RTCRoom(
                    id: res.id, ownerId: res.ownerId, mode: res.mode,
                    role: Role.Broadcaster.rawValue, createTime: res.createTime,
                    mediaParams: res.mediaParams,
                    participants: res.participants
                )
                return Observable.just(room)
            }
    }

    /**
     * 查询房间
     */
    func queryRoom(id: String) -> Observable<RTCRoom> {
        return self.liveApi.queryRoom(id).flatMap {
            res -> Observable<RTCRoom> in
            let room = RTCRoom(
                id: res.id, ownerId: res.ownerId,
                mode: res.mode,
                role: Role.Broadcaster.rawValue, createTime: res.createTime,
                mediaParams: res.mediaParams,
                participants: res.participants
            )
            return Observable.just(room)
        }
    }

    /**
     * 加入房间
     */
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

    /**
     * 向房间成员发送呼叫
     */
    public func callRoomMembers(
        _ id: String, _ msg: String, _ duration: Int64, _ members: Set<Int64>
    ) -> Observable<Void> {
        let req = CallRoomMemberReqVo(
            uId: myUId, roomId: id, msg: msg, duration: duration,
            members: members)
        return self.liveApi.callRoomMembers(req)
    }

    /**
     * 取消向房间成员发送呼叫
     */
    public func cancelCallRoomMembers(
        _ id: String, _ msg: String, _ members: Set<Int64>
    ) -> Observable<Void> {
        let req = CancelCallRoomMemberReqVo(
            uId: myUId, roomId: id, msg: msg, members: members)
        return self.liveApi.cancelCallRoomMembers(req)
    }

    /**
     * 拒绝加入房间(拒绝电话)
     */
    public func refuseJoinRoom(roomId: String, reason: String) -> Observable<
        Void
    > {
        let req = RefuseJoinReqVo(roomId: roomId, uId: myUId, msg: reason)
        return self.liveApi.refuseJoinRoom(req)
    }

    /**
     * 邀请新成员
     */
    public func inviteNewMembers(
        _ id: String,
        _ uIds: Set<Int64>, _ msg: String, _ duration: Int64
    ) -> Observable<Void> {
        let req = InviteMemberReqVo(
            uId: myUId, roomId: id, msg: msg, duration: duration,
            inviteUIds: uIds)
        return self.liveApi.inviteMembers(req)
    }

    /**
     * 踢出成员
     */
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
    public func leaveRoom(id: String, delRoom: Bool) -> Observable<Void> {
        if self.getRoomById(id)?.ownerId == myUId && delRoom {
            let delReq = DelRoomReqVo(roomId: id, uId: myUId)
            return self.liveApi.deleteRoom(delReq).compose(
                RxTransformer.shared.io2Main()
            )
        } else {
            return self.liveApi.leaveRoom(
                LeaveRoomReqVo(uId: myUId, roomId: id, msg: "")
            )
        }
    }

    public func destroyRoom(id: String) {
        guard let room = self.getRoomById(id) else { return }
        self.rtcRooms.removeAll { r in
            r.id == id
        }
        room.destroy()
    }

}
