//
//  LiveApi.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/9/3.
//

import Foundation
import RxSwift

protocol LiveApi {
    
    func createRoom(_ req: CreateRoomReqBean) -> Observable<CreateRoomResBean>
    
    func joinRoom(_ req: JoinRoomReqBean) -> Observable<JoinRoomResBean>
    
    func publishStream(_ req: PublishReqBean) -> Observable<PublishResBean>
    
    func playStream(_ req: PlayReqBean) -> Observable<PlayResBean>
    
}
