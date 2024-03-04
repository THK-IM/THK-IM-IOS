//
//  GroupSessionCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/13.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

open class GroupSessionCell: IMBaseSessionCell {
    
    override open func showSessionEntityInfo(_ session: Session) {
        IMCoreManager.shared.groupModule.findById(id: session.entityId)
            .subscribe(onNext: { [weak self] group in
                guard let g = group else {
                    return
                }
                self?.avatarView.renderImageByUrlWithCorner(url: g.avatar , radius: 10)
                self?.nickView.text = g.name
            }).disposed(by: self.disposeBag)
    }
}

