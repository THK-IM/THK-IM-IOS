//
//  LiveApi.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/9/3.
//

import Foundation
import RxSwift

protocol LiveApi {

    func getEndpoint() -> String

    func createRoom(_ req: CreateRoomReqVo) -> Observable<CreateRoomResVo>

    func joinRoom(_ req: JoinRoomReqVo) -> Observable<JoinRoomResVo>

    func refuseJoinRoom(_ req: RefuseJoinReqVo) -> Observable<Void>

    func deleteRoom(_ req: DelRoomReqVo) -> Observable<Void>

    func publishStream(_ req: PublishStreamReqVo) -> Observable<PublishStreamResVo>

    func playStream(_ req: PlayStreamReqVo) -> Observable<PlayStreamResVo>

}
