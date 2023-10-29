//
//  Previewer.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/10/29.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import UIKit

public class Previewer : IMPreviewer {
    
    init(token: String) {
        IMAVCacheManager.shared.setToken(token: token)
    }
    
    public func previewMessage(_ controller: UIViewController, items: [Message], view: UIView, defaultId: Int64) {
        controller.definesPresentationContext = true
        let mediaPreviewController = MediaPreviewController()
        mediaPreviewController.messages = items
        let absoluteFrame = view.convert(view.bounds, to: nil)
        mediaPreviewController.enterFrame = absoluteFrame
        mediaPreviewController.defaultId = defaultId
        mediaPreviewController.modalPresentationStyle = .overFullScreen
        mediaPreviewController.transitioningDelegate = mediaPreviewController
        controller.present(mediaPreviewController, animated: true)
    }
    
}
