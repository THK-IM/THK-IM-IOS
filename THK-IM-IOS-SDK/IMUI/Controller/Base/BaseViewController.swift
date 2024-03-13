//
//  BaseViewController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/5.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit
import RxSwift
import JDStatusBarNotification
import ProgressHUD

open class BaseViewController: UIViewController, UIGestureRecognizerDelegate {
    
    public let menuItemTagAdd = "add"
    public let menuItemTagSearch = "search"
    
    public let disposeBag = DisposeBag()
    
    override open func viewDidLoad() {
        if (hasTitlebar()) {
            if let title = title() {
                setTitle(title: title)
            }
            var images = [UIImage?]()
            var actions = [Selector?]()
            if hasAddMenu() {
                images.append(menuImages(menu: menuItemTagAdd))
                actions.append(#selector(addTapped))
            }
            if hasSearchMenu() {
                images.append(menuImages(menu: menuItemTagSearch))
                actions.append(#selector(searchTapped))
            }
            setRightItems(images: images, actions: actions)
            if (self.swipeBack()) {
                let backImage = UIImage(named: "ic_titlebar_back")?.scaledToSize(CGSize(width: 24, height: 24))
                let backItem = UIBarButtonItem(image: backImage, style: .plain, target: self, action: #selector(backAction))
                self.navigationItem.leftBarButtonItem = backItem
            }
        }
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        self.navigationItem.hidesBackButton = true
        self.navigationController?.interactivePopGestureRecognizer?.delegate = self
        self.navigationController?.navigationBar.isHidden = !hasTitlebar()
        super.viewWillAppear(animated)
    }
    
    open func hasTitlebar() -> Bool {
        return true
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    @objc open func backAction() {
        self.navigationController?.popViewController(animated: true)
    }
    
    open func title() -> String? {
        return nil
    }
    
    open func hasAddMenu() -> Bool {
        return false
    }
    
    open func hasSearchMenu() -> Bool {
        return false
    }
    
    open func menuImages(menu: String) -> UIImage? {
        var image: UIImage? = nil
        if (menu == menuItemTagAdd) {
            image = UIImage(named: "ic_titlebar_add")
        } else if (menu == menuItemTagSearch) {
            image = UIImage(named: "ic_titlebar_search")
        }
        if image == nil {
            return image
        }
        return image!.scaledToSize(CGSize(width: 24, height: 24))
    }
    
    open func onMenuClick(menu: String) {
        
    }
    
    open func showError(_ err: Error) {
        if let codeMessageErr = err as? CodeMessageError {
            showToast(codeMessageErr.message)
        } else {
            showToast("未知错误")
        }
    }
    
    
    @objc func addTapped() {
        onMenuClick(menu: menuItemTagAdd)
    }
    
    @objc func searchTapped() {
        onMenuClick(menu: menuItemTagSearch)
    }
    
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return true
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return self.swipeBack()
    }
    
    open func swipeBack() -> Bool {
        return self.navigationController?.children.count ?? 0 > 1
    }
    
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    public func getTitleBarHeight() -> CGFloat {
        var navigationBarHeight = 0.0
        if self.navigationController != nil {
            navigationBarHeight += navigationController!.navigationBar.frame.height
        }
        return navigationBarHeight + AppUtils.getStatusBarHeight()
    }
    
    public func getNavHeight() -> CGFloat {
        var navHeight: CGFloat = 0
        if (self.navigationController != nil) {
            navHeight = self.navigationController!.navigationBar.frame.size.height
        }
        return navHeight + UIApplication.shared.windows[0].safeAreaInsets.top
    }
    
}
