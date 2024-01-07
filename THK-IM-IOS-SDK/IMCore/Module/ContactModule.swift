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
    
    func queryAllContacts() -> Observable<Array<Contact>>
    
}
