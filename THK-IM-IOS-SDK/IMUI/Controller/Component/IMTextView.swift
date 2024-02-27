//
//  IMTextView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/21.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit

protocol TextViewBackwardDelegate: AnyObject {

    func onDeleted() -> Bool
}

class IMTextView: UITextView {
    
    weak var backwardDelegate:TextViewBackwardDelegate?
    
    override func deleteBackward() {
        if (backwardDelegate == nil) {
            super.deleteBackward()
        } else {
            if (!backwardDelegate!.onDeleted()) {
                super.deleteBackward()
            }
        }
    }
}
