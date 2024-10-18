//
//  SingleSessionCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/4.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation

open class SingleSessionCell: IMBaseSessionCell {

    override open func showSessionEntityInfo(_ session: Session) {
        IMCoreManager.shared.userModule.queryUser(id: session.entityId)
            .subscribe(onNext: { [weak self] user in
                if user.avatar == nil || user.avatar!.isEmpty {
                    let image = IMUIManager.shared.uiResourceProvider?.avatar(user: user)
                    self?.avatarView.image = image
                } else {
                    self?.avatarView.renderImageByUrlWithCorner(url: user.avatar ?? "", radius: 10)
                }
                self?.nickView.text = user.nickname
            }).disposed(by: self.disposeBag)
    }
}
