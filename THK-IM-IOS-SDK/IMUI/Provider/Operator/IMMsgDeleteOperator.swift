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
        return ResourceUtils.loadString("delete")
    }

    public func icon() -> UIImage? {
        return ResourceUtils.loadImage(named: "ic_msg_opr_delete")?.withTintColor(
            IMUIManager.shared.uiResourceProvider?.inputTextColor()
                ?? UIColor.init(hex: "333333"))
    }

    public func onClick(sender: IMMsgSender, message: Message) {
        var deleteServer = message.sendStatus == MsgSendStatus.Success.rawValue
        IMCoreManager.shared.messageModule
            .deleteMessages(message.sessionId, [message], deleteServer)
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
