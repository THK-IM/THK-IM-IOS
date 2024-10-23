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

    public init() {

    }

    open func queryServerGroupById(id: Int64) -> RxSwift.Observable<Group> {
        return Observable.just(Group(id: id))
    }

    open func findById(id: Int64) -> RxSwift.Observable<Group> {
        return Observable.create({ observer -> Disposable in
            let group = IMCoreManager.shared.database.groupDao().findById(id)
            if (group != nil) {
                observer.onNext(group!)
            } else {
                observer.onNext(Group(id: id))
            }
            observer.onCompleted()
            return Disposables.create()
        }).flatMap({ group -> Observable<Group> in
            if group.cTime == 0 {
                return self.queryServerGroupById(id: id).flatMap({ group -> Observable<Group> in
                    try? IMCoreManager.shared.database.groupDao().insertOrReplace([group])
                    return Observable.just(group)
                })
            } else {
                return Observable.just(group)
            }
        })
    }

    open func queryAllGroups() -> RxSwift.Observable<[Group]> {
        return Observable.create({ observer -> Disposable in
            let groups = IMCoreManager.shared.database.groupDao().findAll()
            observer.onNext(groups)
            observer.onCompleted()
            return Disposables.create()
        })
    }

    open func onSignalReceived(_ type: Int, _ body: String) {

    }

    open func reset() {
    }

}
