//
//  LiveApi.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/9/3.
//

import Foundation
import RxSwift

public protocol LiveApi {

    func getEndpoint() -> String

    func createRoom(_ req: CreateRoomReqVo) -> Observable<RoomResVo>
    
    func queryRoom(_ id: String) -> Observable<RoomResVo>
    
    func callRoomMembers(_ req: CallRoomMemberReqVo) -> Observable<Void>
    
    func cancelCallRoomMembers(_ req: CancelCallRoomMemberReqVo) -> Observable<Void>

    func joinRoom(_ req: JoinRoomReqVo) -> Observable<JoinRoomResVo>
    
    func inviteMembers(_ req: InviteMemberReqVo) -> Observable<Void>

    func refuseJoinRoom(_ req: RefuseJoinReqVo) -> Observable<Void>
    
    func kickoffMember(_ req: KickoffMemberReqVo) -> Observable<Void>

    func deleteRoom(_ req: DelRoomReqVo) -> Observable<Void>

    func publishStream(_ req: PublishStreamReqVo) -> Observable<PublishStreamResVo>

    func playStream(_ req: PlayStreamReqVo) -> Observable<PlayStreamResVo>

}
