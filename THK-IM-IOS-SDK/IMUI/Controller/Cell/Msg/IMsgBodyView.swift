//
//  IMsgBodyView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/2/24.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit

public protocol IMsgBodyView: AnyObject {

    func setViewPosition(_ position: IMMsgPosType)

    func setMessage(
        _ message: Message, _ session: Session?, _ delegate: IMMsgCellOperator?
    )

    func contentView() -> UIView

    func onViewDisappear()

    func onViewAppear()
}

extension IMsgBodyView {
    public func onViewDisappear() {}
    public func onViewAppear() {}
}
