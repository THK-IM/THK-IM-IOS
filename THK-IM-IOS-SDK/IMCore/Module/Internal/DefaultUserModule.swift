//
//  DefaultUserModule.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/4.
//

import Foundation
import RxSwift

open class DefaultUserModule : UserModule {
    
    public func queryServerUser(id: Int64) -> RxSwift.Observable<User> {
        return Observable.create({observer -> Disposable in
            let now = Date().timeMilliStamp
            let user = User(
                id: id, displayId: "", name: "user-\(id)", avatar: "https://picsum.photos/300/300",
                sex: 0, status: 1, cTime: now, mTime: now
            )
            observer.onNext(user)
            observer.onCompleted()
            return Disposables.create()
        })
    }
    
    public func queryUser(id: Int64) -> RxSwift.Observable<User> {
        return Observable.create({ observer -> Disposable in
            let user = IMCoreManager.shared.database.userDao().findById(id)
            if (user == nil) {
                observer.onNext(User(id: id, displayId: "", name: "", avatar: "", sex: 0, status: 0, cTime: 0, mTime: 0))
            } else {
                observer.onNext(user!)
            }
            observer.onCompleted()
            return Disposables.create()
        }).flatMap({ (user) -> Observable<User> in
            if (user.cTime == 0) {
                return self.queryServerUser(id: id).flatMap({(user) -> Observable<User> in
                    try? IMCoreManager.shared.database.userDao().insertOrReplace([user])
                    return Observable.just(user)
                })
            } else {
                return Observable.just(user)
            }
        })
    }
    
    public func queryUsers(ids: Set<Int64>) -> RxSwift.Observable<Dictionary<Int64, User>> {
        return Observable.create({ observer -> Disposable in
            let users = IMCoreManager.shared.database.userDao().findByIds(ids)
            var userMap = Dictionary<Int64, User>()
            if users != nil {
                for user in users! {
                    userMap[user.id] = user
                }
            }
            observer.onNext(userMap)
            observer.onCompleted()
            return Disposables.create()
        })
    }
    
    public func onUserInfoUpdate(user: User) {
        try? IMCoreManager.shared.database.userDao().insertOrReplace([user])
    }
    
    public func onSignalReceived(_ type: Int, _ body: String) {
        
    }
    
    
}
