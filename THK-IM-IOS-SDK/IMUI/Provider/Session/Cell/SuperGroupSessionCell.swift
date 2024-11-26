//
//  SuperGroupSessionCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/2/17.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

open class SuperGroupSessionCell: IMBaseSessionCell {

    open override func renderSessionEntityInfo() {
        guard let session = self.session else { return }
        IMCoreManager.shared.groupModule.findById(id: session.entityId)
            .subscribe(onNext: { [weak self] group in
                self?.avatarView.renderImageByUrlWithCorner(url: group.avatar, radius: 10)
                self?.nickView.text = group.name
            }).disposed(by: self.disposeBag)
    }
}
