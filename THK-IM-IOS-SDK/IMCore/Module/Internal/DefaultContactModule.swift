//
//  DefaultContactorModule.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/12/7.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import RxSwift


open class DefaultContactModule: ContactModule {
    
    public func syncContacts() {
        
    }
    
    public func queryAllContacts() -> RxSwift.Observable<Array<Contact>> {
        return Observable.create({ observer -> Disposable in
            let contacts = IMCoreManager.shared.database.contactDao().findAll()
            observer.onNext(contacts)
            observer.onCompleted()
            return Disposables.create()
        })
    }
    
    public func onSignalReceived(_ type: Int, _ body: String) {
        
    }
    
}
