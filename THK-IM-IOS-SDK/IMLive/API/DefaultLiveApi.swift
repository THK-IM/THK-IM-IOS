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
    
    let roomApi = MoyaProvider<RoomApi>(plugins: [NetworkLoggerPlugin()])
    let streamApi = MoyaProvider<StreamApi>(plugins: [NetworkLoggerPlugin()])
    
    func createRoom(_ req: CreateRoomReqBean) -> Observable<CreateRoomResBean> {
        return roomApi.rx
            .request(.createRoom(req))
            .asObservable()
            .compose(DefaultRxTransformer.response2Bean(CreateRoomResBean.self))
    }
    
    func joinRoom(_ req: JoinRoomReqBean) -> Observable<JoinRoomResBean> {
        return roomApi.rx
            .request(.joinRoom(req))
            .asObservable()
            .compose(DefaultRxTransformer.response2Bean(JoinRoomResBean.self))
    }
    
    func publishStream(_ req: PublishReqBean) -> Observable<PublishResBean> {
        return streamApi.rx
            .request(.requestPublish(req))
            .asObservable()
            .compose(DefaultRxTransformer.response2Bean(PublishResBean.self))
    }
    
    func playStream(_ req: PlayReqBean) -> Observable<PlayResBean> {
        return streamApi.rx
            .request(.requestPlay(req))
            .asObservable()
            .compose(DefaultRxTransformer.response2Bean(PlayResBean.self))
    }
}
