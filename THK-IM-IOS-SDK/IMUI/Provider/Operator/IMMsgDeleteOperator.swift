//
//  IMMsgDeleteOperator.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/12.
//  Copyright © 2023 THK. All rights reserved.
//

import UIKit
import RxSwift

public class IMMsgDeleteOperator: IMMessageOperator {
    
    private let disposeBag = DisposeBag()
    
    public func id() -> String {
        return "Delete"
    }
    
    public func title() -> String {
        return "删除"
    }
    
    public func icon() -> UIImage? {
        return UIImage(named: "icon_msg_operate_cancel")
    }
    
    public func onClick(sender: IMMsgSender, message: Message) {
        IMCoreManager.shared.getMessageModule()
            .deleteMessages(message.sessionId, [message], true)
            .compose(RxTransformer.shared.io2Main())
            .subscribe(onError: { error in
            }, onCompleted: {
            }).disposed(by: self.disposeBag)
    }
    
    
}