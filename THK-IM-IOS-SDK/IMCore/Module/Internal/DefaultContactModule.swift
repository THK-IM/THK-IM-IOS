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
    
    public init() {
        
    }
    
    open func syncContacts() {
        
    }
    
    
    public func updateContact(_ contact: Contact) -> RxSwift.Observable<Void> {
        return Observable.create({ observer -> Disposable in
            try? IMCoreManager.shared.database.contactDao().insertOrIgnore([contact])
            observer.onCompleted()
            return Disposables.create()
        })
    }
    
    
    open func queryServerContactByUserId(_ id: Int64) -> Observable<Contact> {
        let contact = Contact(id: id, relation: 0, cTime: 0, mTime: 0)
        return Observable.just(contact)
    }
    
    open func queryContactByUserId(_ id: Int64) -> Observable<Contact> {
        return Observable.create({ observer -> Disposable in
            let contact = IMCoreManager.shared.database.contactDao().findByUserId(id)
            observer.onNext(contact)
            observer.onCompleted()
            return Disposables.create()
        }).flatMap { contact in
            if contact != nil {
                return Observable.just(contact!)
            } else {
                return self.queryServerContactByUserId(id)
            }
        }
    }
    
    open func queryAllContacts() -> RxSwift.Observable<Array<Contact>> {
        return Observable.create({ observer -> Disposable in
            let contacts = IMCoreManager.shared.database.contactDao().findAll()
            observer.onNext(contacts)
            observer.onCompleted()
            return Disposables.create()
        })
    }
    
    open func onSignalReceived(_ type: Int, _ body: String) {
        
    }
    
    
    open func reset() {
    }
    
}
