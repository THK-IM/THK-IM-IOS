//
//  DefaultGroupModule.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/12/7.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import RxSwift

open class DefaultGroupModule: GroupModule {
    
    public func queryServerGroupById(id: Int64) -> RxSwift.Observable<Group?> {
        return Observable.just(Group(id: id))
    }
    
    public func findById(id: Int64) -> RxSwift.Observable<Group?> {
        return Observable.create({ observer -> Disposable in
            let group = IMCoreManager.shared.database.groupDao().findById(id)
            observer.onNext(group)
            observer.onCompleted()
            return Disposables.create()
        })
    }
    
    public func queryAllGroups() -> RxSwift.Observable<Array<Group>> {
        return Observable.create({ observer -> Disposable in
            let groups = IMCoreManager.shared.database.groupDao().findAll()
            observer.onNext(groups)
            observer.onCompleted()
            return Disposables.create()
        })
    }
    
    public func onSignalReceived(_ type: Int, _ body: String) {
        
    }
    
}
