//
//  PreviewCellView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/10/29.
//  Copyright © 2023 THK. All rights reserved.
//

import UIKit
import RxSwift


open class PreviewCellView: UICollectionViewCell {
    
    weak var delegate: PreviewDelegate? = nil
    var message: Message? = nil
    var disposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func setMessage(_ message: Message) {
        self.message = message
    }
    
    open func startPreview() {
        guard let vc = self.parentController() as? IMMediaPreviewController else { return }
        let player = vc.videoPlayer
        if player.view.superview != nil {
            player.view.removeFromSuperview()
        }
    }
    
    open func onIMLoadProgress(_ loadProgress: IMLoadProgress) {}
    
    func parentController() -> UIViewController? {
        var responder: UIResponder? = self
        while let nextResponder = responder?.next {
            if let viewController = nextResponder as? UIViewController {
                return viewController
            }
            responder = nextResponder
        }
        return nil
    }
    
}

