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
import BadgeSwift

extension UIViewController {
    
    public func setTitle(title: String) {
        let titleView = UILabel(frame: CGRect.init(x: 0, y: -20, width: 150, height: 30))
        titleView.text = title
        titleView.textAlignment = .center
        titleView.font = UIFont.systemFont(ofSize: 18)
        titleView.textColor = UIColor.black
        self.navigationItem.titleView = titleView
        self.navigationItem.titleView?.contentMode = .center
    }
    
    public func setRightItems(images: [UIImage?], titles: [String], actions: [Selector?]) {
        var rightBarButtonItems = [UIBarButtonItem]()
        var i = 0
        for image in images {
            let item = UIBarButtonItem(title: titles[i], style: .plain, target: self, action: nil)
            let customButton = UIButton(type: .custom)
            customButton.frame = CGRect(x: 0, y: 0, width: 48, height: 48)
            if let action = actions[i] {
                customButton.addTarget(self, action: action, for: .touchUpInside)
            }
            customButton.setImage(image, for: .normal)
            let b = BadgeSwift(frame: CGRect(x: 24, y: 0, width: 24, height: 24))
            b.textColor = .white
            b.insets = CGSize(width: 0, height: 0)
            b.font = UIFont.systemFont(ofSize: 12)
            b.isHidden = true
            customButton.addSubview(b)
            item.customView = customButton
            rightBarButtonItems.append(item)
            i+=1
        }
        self.navigationItem.rightBarButtonItems = rightBarButtonItems
    }
    
    public func setNavigationItemBadge(_ count: Int64, title: String) {
        var text: String? = ""
        if count <= 0 {
            text = nil
        } else if count >= 100 {
            text = "99+"
        } else {
            text = "\(count)"
        }
        if let rightBarButtonItems = self.navigationItem.rightBarButtonItems {
            for item in rightBarButtonItems {
                if title == title {
                    item.customView?.subviews.forEach({ view in
                        if (view is BadgeSwift) {
                            if text == nil {
                                (view as? BadgeSwift)?.isHidden = true
                            } else {
                                (view as? BadgeSwift)?.isHidden = false
                                (view as? BadgeSwift)?.text = text
                            }
                        }
                    })
                }
            }
        }
    }
    
    public func showLoading(text: String? = nil) {
        ProgressHUD.animate(text, .horizontalBarScaling, interaction: false)
    }
    
    public func dismissLoading() {
        ProgressHUD.dismiss()
    }
    
    public func showToast(_ toast: String, _ success: Bool = true) {
        NotificationPresenter.shared.present(toast)
        NotificationPresenter.shared.dismiss(after: 1)
    }
    
}
