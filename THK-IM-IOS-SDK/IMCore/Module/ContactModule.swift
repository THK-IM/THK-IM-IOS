//
//  ContactModule.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/18.
//

import Foundation
import RxSwift

public protocol ContactModule : BaseModule {
    
    func syncContacts()
    
    func updateContact(_ contact: Contact) -> Observable<Void>
    
    func queryContactByUserId(_ id: Int64) -> Observable<Contact>
    
    func queryAllContacts() -> Observable<Array<Contact>>
    
    func queryContactsByRelation(_ relation: Int) -> Observable<Array<Contact>>
    
}
