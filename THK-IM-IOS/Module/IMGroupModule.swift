//
//  IMGroupModule.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/7.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation
import RxSwift

class IMGroupModule: DefaultGroupModule {
    
    override func queryServerGroupById(id: Int64) -> Observable<Group?> {
        return DataRepository.shared.groupApi.rx.request(.queryGroup(id))
            .asObservable()
            .compose(RxTransformer.shared.response2Bean(GroupVo.self))
            .flatMap({ groupVo in
                return Observable.just(groupVo.toGroup())
            })
    }
}

