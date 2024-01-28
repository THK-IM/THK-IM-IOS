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
    
    func createRoom(_ req: CreateRoomReqVo) -> Observable<CreateRoomResVo> {
        return roomApi.rx
            .request(.createRoom(req))
            .asObservable()
            .compose(RxTransformer.shared.response2Bean(CreateRoomResVo.self))
    }
    
    func joinRoom(_ req: JoinRoomReqVo) -> Observable<JoinRoomResVo> {
        return roomApi.rx
            .request(.joinRoom(req))
            .asObservable()
            .compose(RxTransformer.shared.response2Bean(JoinRoomResVo.self))
    }
    
    func publishStream(_ req: PublishStreamReqVo) -> Observable<PublishStreamRespVo> {
        return streamApi.rx
            .request(.requestPublish(req))
            .asObservable()
            .compose(RxTransformer.shared.response2Bean(PublishStreamRespVo.self))
    }
    
    func playStream(_ req: PlayStreamRequestVo) -> Observable<PlayStreamResponseVo> {
        return streamApi.rx
            .request(.requestPlay(req))
            .asObservable()
            .compose(RxTransformer.shared.response2Bean(PlayStreamResponseVo.self))
    }
}
