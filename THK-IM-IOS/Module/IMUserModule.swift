//
//  IMUserModule.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/7.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation
import RxSwift

class IMUserModule: DefaultUserModule {
    
    override func queryServerUser(id: Int64) -> Observable<User> {
        print("queryServerUser \(id)")
        return DataRepository.shared.userApi.rx.request(.queryUser(id))
            .asObservable()
            .compose(RxTransformer.shared.response2Bean(UserVo.self))
            .flatMap({ userVo in
                let user = userVo.toUser()
                try? IMCoreManager.shared.database.userDao().insertOrReplace([user])
                return Observable.just(user)
            })
    }
    
}
