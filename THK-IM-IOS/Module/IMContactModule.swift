//
//  IMContactModule.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/7.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation
import RxSwift

class IMContactModule: DefaultContactModule {

    private let disposeBag = DisposeBag()

    private func setContactSyncTime(_ time: Int64) -> Bool {
        let key = "/\(IMCoreManager.shared.uId)/contact_sync_time"
        let saveTime = IMCoreManager.shared.severTime
        UserDefaults.standard.setValue(saveTime, forKey: key)
        return UserDefaults.standard.synchronize()
    }

    private func getContactLastSyncTime() -> Int64 {
        let key = "/\(IMCoreManager.shared.uId)/contact_sync_time"
        let value = UserDefaults.standard.object(forKey: key)
        let time = value == nil ? 0 : (value as! Int64)
        return time
    }

    override func syncContacts() {
        let uId = IMCoreManager.shared.uId
        let mTime = getContactLastSyncTime()
        let count = 200
        let offset = 0

        DataRepository.shared.contactApi.rx.request(
            .queryLatestContactList(uId, mTime, count, offset)
        )
        .asObservable()
        .compose(RxTransformer.shared.response2Bean(ListVo<ContactVo>.self))
        .flatMap({ contactListVo in
            let contactList = contactListVo.data.map({ contactVo in
                return contactVo.toContact()
            })
            try IMCoreManager.shared.database.contactDao().insertOrReplace(contactList)
            return Observable.just(contactList)
        }).subscribe(onNext: { contactList in
            if !contactList.isEmpty {
                let success = self.setContactSyncTime(contactList.last!.mTime)
                if success && contactList.count >= count {
                    self.syncContacts()
                }
            }
        }).disposed(by: self.disposeBag)
    }

}
