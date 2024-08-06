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
    
    open func queryServerContactsByIds(_ ids: Array<Int64>) -> RxSwift.Observable<Array<Contact>> {
        return Observable.create({ observer -> Disposable in
            var contacts = Array<Contact>()
            for id in ids {
                let c = Contact(id: id, relation: 0, cTime: IMCoreManager.shared.severTime, mTime: IMCoreManager.shared.severTime)
                contacts.append(c)
            }
            observer.onNext(contacts)
            observer.onCompleted()
            return Disposables.create()
        })
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
    
    
    
    public func queryContactsByUserIds(_ ids: Array<Int64>) -> RxSwift.Observable<Array<Contact>> {
        return Observable.create({ observer -> Disposable in
            let contacts = IMCoreManager.shared.database.contactDao().findByUserIds(ids)
            observer.onNext(contacts)
            observer.onCompleted()
            return Disposables.create()
        }).flatMap { contacts -> Observable<Array<Contact>> in
            if (ids.count == contacts.count) {
                return Observable.just(contacts)
            }
            var unknowUIds = [Int64]()
            for id in ids {
                var contain = false
                for c in contacts {
                    if (c.id == id) {
                        contain = true
                        break
                    }
                }
                if !contain {
                    unknowUIds.append(id)
                }
            }
            if unknowUIds.isEmpty {
                return Observable.just(contacts)
            }
            return self.queryServerContactsByIds(unknowUIds)
                .flatMap { serverContacts -> Observable<Array<Contact>>  in
                    try? IMCoreManager.shared.database.contactDao().insertOrReplace(serverContacts)
                    var fullContacts = Array<Contact>()
                    fullContacts.append(contentsOf: contacts)
                    fullContacts.append(contentsOf: serverContacts)
                    return Observable.just(fullContacts)
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
    
    open func queryContactsByRelation(_ relation: Int) -> Observable<Array<Contact>> {
        return Observable.create({ observer -> Disposable in
            let contacts = IMCoreManager.shared.database.contactDao().findByRelation(relation)
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
