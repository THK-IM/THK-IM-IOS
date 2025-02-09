//
//  DefaultLiveApi.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/9/3.
//

import Foundation
import Moya
import RxSwift

class DefaultLiveApi: LiveApi {

    private var endpoint: String
    private var token: String
    private let apiInterceptor: APITokenInterceptor
    private let roomApi: MoyaProvider<RoomApi>
    private let streamApi: MoyaProvider<StreamApi>

    public init(token: String, endpoint: String) {
        self.endpoint = endpoint
        self.token = token
        self.apiInterceptor = APITokenInterceptor(token: token)
        self.apiInterceptor.addValidEndpoint(endpoint: endpoint)
        self.roomApi = MoyaProvider<RoomApi>(plugins: [self.apiInterceptor])
        self.streamApi = MoyaProvider<StreamApi>(plugins: [self.apiInterceptor])
    }

    public func getEndpoint() -> String {
        return self.endpoint
    }

    public func getToken() -> String {
        return self.token
    }

    public func updateToken(token: String) {
        self.token = token
        self.apiInterceptor.updateToken(token: token)
    }

    public func createRoom(_ req: CreateRoomReqVo) -> Observable<RoomResVo> {
        return roomApi.rx
            .request(.createRoom(req))
            .asObservable()
            .compose(RxTransformer.shared.response2Bean(RoomResVo.self))
    }

    public func queryRoom(_ id: String) -> Observable<RoomResVo> {
        return roomApi.rx
            .request(.queryRoom(id))
            .asObservable()
            .compose(RxTransformer.shared.response2Bean(RoomResVo.self))
    }

    func callRoomMembers(_ req: CallRoomMemberReqVo) -> RxSwift.Observable<Void>
    {
        return roomApi.rx
            .request(.callRoomMembers(req))
            .asObservable()
            .compose(RxTransformer.shared.response2Void())
    }

    func cancelCallRoomMembers(_ req: CancelCallRoomMemberReqVo)
        -> RxSwift.Observable<Void>
    {
        return roomApi.rx
            .request(.cancelCallRoomMembers(req))
            .asObservable()
            .compose(RxTransformer.shared.response2Void())
    }

    public func joinRoom(_ req: JoinRoomReqVo) -> Observable<JoinRoomResVo> {
        return roomApi.rx
            .request(.joinRoom(req))
            .asObservable()
            .compose(RxTransformer.shared.response2Bean(JoinRoomResVo.self))
    }

    public func leaveRoom(_ req: LeaveRoomReqVo) -> Observable<Void> {
        return roomApi.rx
            .request(.leaveRoom(req))
            .asObservable()
            .compose(RxTransformer.shared.response2Void())
    }

    func inviteMembers(_ req: InviteMemberReqVo) -> RxSwift.Observable<Void> {
        return roomApi.rx
            .request(.inviteMembers(req))
            .asObservable()
            .compose(RxTransformer.shared.response2Void())
    }

    public func refuseJoinRoom(_ req: RefuseJoinReqVo)
        -> RxSwift.Observable<Void>
    {
        return roomApi.rx
            .request(.refuseJoinRoom(req))
            .asObservable()
            .compose(RxTransformer.shared.response2Void())
    }

    func kickoffMember(_ req: KickoffMemberReqVo) -> RxSwift.Observable<Void> {
        return roomApi.rx
            .request(.kickoffRoomMember(req))
            .asObservable()
            .compose(RxTransformer.shared.response2Void())
    }

    public func deleteRoom(_ req: DelRoomReqVo) -> RxSwift.Observable<Void> {
        return roomApi.rx
            .request(.delRoom(req))
            .asObservable()
            .compose(RxTransformer.shared.response2Void())
    }

    public func publishStream(_ req: PublishStreamReqVo) -> Observable<
        PublishStreamResVo
    > {
        return streamApi.rx
            .request(.requestPublish(req))
            .asObservable()
            .compose(
                RxTransformer.shared.response2Bean(PublishStreamResVo.self))
    }

    public func playStream(_ req: PlayStreamReqVo) -> Observable<
        PlayStreamResVo
    > {
        return streamApi.rx
            .request(.requestPlay(req))
            .asObservable()
            .compose(RxTransformer.shared.response2Bean(PlayStreamResVo.self))
    }
}
