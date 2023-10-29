//
//  PreviewCellView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/10/29.
//  Copyright © 2023 THK. All rights reserved.
//

import UIKit
import RxSwift


class PreviewCellView: UICollectionViewCell {
    
    var message: Message? = nil
    var disposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func setMessage(_ message: Message) {
        self.message = message
    }
    
    open func startPreview() {
        
    }
    
    open func stopPreview() {
        
    }
    
}

