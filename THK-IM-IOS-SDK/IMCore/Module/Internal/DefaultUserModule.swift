//
//  DefaultUserModule.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/4.
//

import Foundation
import RxSwift

open class DefaultUserModule : UserModule {
    
    public init() {
        
    }
    
    open func reset() {
        
    }
    
    open func queryServerUsers(ids: Set<Int64>) -> RxSwift.Observable<Dictionary<Int64, User>> {
        var userMap = Dictionary<Int64, User>()
        for id in ids {
            userMap[id] = User(id: id)
        }
        return Observable.just(userMap)
    }
    
    open func queryServerUser(id: Int64) -> RxSwift.Observable<User> {
        return Observable.just(User(id:id))
    }
    
    open func queryUser(id: Int64) -> RxSwift.Observable<User> {
        return Observable.create({ observer -> Disposable in
            let user = IMCoreManager.shared.database.userDao().findById(id)
            if (user == nil) {
                observer.onNext(User(id: id))
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
    
    open func queryUsers(ids: Set<Int64>) -> RxSwift.Observable<Dictionary<Int64, User>> {
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
        }).flatMap { userMap in
            var notFoundIds = Set<Int64>()
            for id in ids {
                if userMap[id] == nil {
                    notFoundIds.insert(id)
                }
            }
            if notFoundIds.count == 0 {
                return Observable.just(userMap)
            } else {
                return self.queryServerUsers(ids: notFoundIds).flatMap { serverUserMap in
                    var fullUserMap = Dictionary<Int64, User>()
                    for (k, v) in serverUserMap {
                        fullUserMap[k] = v
                    }
                    for (k, v) in userMap {
                        fullUserMap[k] = v
                    }
                    return Observable.just(fullUserMap)
                }
            }
        }
    }
    
    public func onUserInfoUpdate(user: User) {
        try? IMCoreManager.shared.database.userDao().insertOrReplace([user])
    }
    
    public func onSignalReceived(_ type: Int, _ body: String) {
        
    }
    
    
}
