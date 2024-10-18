//
//  GroupModule.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/18.
//

import Foundation
import RxSwift

public protocol GroupModule: BaseModule {

    func queryServerGroupById(id: Int64) -> Observable<Group?>

    func findById(id: Int64) -> Observable<Group?>

    func queryAllGroups() -> Observable<[Group]>

}
