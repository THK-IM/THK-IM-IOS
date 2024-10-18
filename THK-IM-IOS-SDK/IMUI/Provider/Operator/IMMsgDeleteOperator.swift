//
//  IMMsgDeleteOperator.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/12.
//  Copyright © 2023 THK. All rights reserved.
//

import RxSwift
import UIKit

public class IMMsgDeleteOperator: IMMessageOperator {

    private let disposeBag = DisposeBag()

    public func id() -> String {
        return "Delete"
    }

    public func title() -> String {
        return ResourceUtils.loadString("delete", comment: "")
    }

    public func icon() -> UIImage? {
        return ResourceUtils.loadImage(named: "ic_msg_opr_delete")
    }

    public func onClick(sender: IMMsgSender, message: Message) {
        IMCoreManager.shared.messageModule
            .deleteMessages(message.sessionId, [message], true)
            .compose(RxTransformer.shared.io2Main())
            .subscribe(
                onError: { error in
                },
                onCompleted: {
                }
            ).disposed(by: self.disposeBag)
    }

    public func supportMessage(_ message: Message, _ session: Session) -> Bool {
        return true
    }

}
