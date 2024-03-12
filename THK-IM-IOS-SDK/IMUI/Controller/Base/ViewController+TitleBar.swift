//
//  ViewController+TitleBar.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit

import JDStatusBarNotification
import ProgressHUD

extension UIViewController {
    
    func setTitle(title: String) {
        let titleView = UILabel(frame: CGRect.init(x: 0, y: -20, width: 150, height: 30))
        titleView.text = title
        titleView.textAlignment = .center
        titleView.font = UIFont.systemFont(ofSize: 18)
        titleView.textColor = UIColor.black
        self.navigationItem.titleView = titleView
        self.navigationItem.titleView?.contentMode = .center
    }
    
    func setRightItems(images: [UIImage?], actions: [Selector?]) {
        var rightBarButtonItems = [UIBarButtonItem]()
        var i = 0
        for image in images {
            let item = UIBarButtonItem(image: image, style: .plain, target: self, action: actions[i])
            item.width = 24
            rightBarButtonItems.append(item)
            i+=1
        }
        self.navigationItem.rightBarButtonItems = rightBarButtonItems
    }
    
    public func showLoading(text: String? = nil) {
        ProgressHUD.animate(text, .horizontalBarScaling, interaction: true)
    }
    
    public func dismissLoading() {
        ProgressHUD.dismiss()
    }
    
    public func showToast(_ toast: String, _ success: Bool = true) {
        NotificationPresenter.shared.present(toast)
        NotificationPresenter.shared.dismiss(after: 1)
    }
    
}
