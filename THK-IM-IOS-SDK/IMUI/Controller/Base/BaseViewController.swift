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
import SwiftEntryKit

open class BaseViewController: UIViewController, UIGestureRecognizerDelegate {
    
    public let menuItemTagNews = "News"
    public let menuItemTagAdd = "add"
    public let menuItemTagSearch = "search"
    public let menuSize = CGSize(width: 30, height: 30)
    open var isNavigationBarHidden = false
    
    public let disposeBag = DisposeBag()
    
    override open func viewDidLoad() {
        if (hasTitlebar()) {
            if let title = title() {
                setTitle(title: title)
            }
            var images = [UIImage?]()
            var actions = [Selector?]()
            var titles = [String]()
            if hasNewsMenu() {
                titles.append(menuItemTagNews)
                images.append(menuImages(menu: menuItemTagNews))
                actions.append(#selector(newsTapped))
            }
            if hasAddMenu() {
                titles.append(menuItemTagAdd)
                images.append(menuImages(menu: menuItemTagAdd))
                actions.append(#selector(addTapped))
            }
            if hasSearchMenu() {
                titles.append(menuItemTagSearch)
                images.append(menuImages(menu: menuItemTagSearch))
                actions.append(#selector(searchTapped))
            }
            setRightItems(images: images, titles: titles, actions: actions)
            if (self.swipeBack()) {
                let backImage = UIImage(named: "ic_titlebar_back")?.scaledToSize(CGSize(width: 24, height: 24))
                let backItem = UIBarButtonItem(image: backImage, style: .plain, target: self, action: #selector(backAction))
                self.navigationItem.leftBarButtonItem = backItem
            }
        }
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTouched))
        tapGesture.cancelsTouchesInView = false  // 这样不会阻止其他控件接收 touch 事件
        self.view.addGestureRecognizer(tapGesture)
        self.navigationController?.isNavigationBarHidden = isNavigationBarHidden
    }
    
    @objc open func viewTouched() {
        self.view.endEditing(true)
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
    
    open func hasNewsMenu() -> Bool {
        return false
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
        return image!.scaledToSize(menuSize)
    }
    
    open func hasBadge(menu: String) -> Bool {
        return false
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
    
    @objc func newsTapped() {
        onMenuClick(menu: menuItemTagNews)
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
    
    open func getTitleBarHeight() -> CGFloat {
        var navigationBarHeight = 0.0
        if self.navigationController != nil {
            navigationBarHeight += navigationController!.navigationBar.frame.height
        }
        return navigationBarHeight + AppUtils.getStatusBarHeight()
    }
    
    open func getNavHeight() -> CGFloat {
        var navHeight: CGFloat = 0
        if (self.navigationController != nil) {
            navHeight = self.navigationController!.navigationBar.frame.size.height
        }
        return navHeight + UIApplication.shared.windows[0].safeAreaInsets.top
    }
    
    // 显示自定义的警告对话框
    open func showDialog(
        title: String, message: String?, okString: String, cancelString: String, extraString: String?,
        _ ok: @escaping () -> Void, _ cancel: @escaping () -> Void, _ extra: (() -> Void)?
    ) {
        var subViews = [UIView]()
        // 定义外观属性
        var attributes = EKAttributes.centerFloat
        attributes.windowLevel = .normal
        attributes.hapticFeedbackType = .success
        attributes.displayDuration = .infinity // 对话框会一直显示直到用户交互
        attributes.entryBackground = .color(color: EKColor(UIColor.white)) // 背景颜色
        attributes.shadow = .active(with: .init(color: EKColor(UIColor.black.withAlphaComponent(0.3)), opacity: 1, radius: 10))
        attributes.screenBackground = .color(color: EKColor(UIColor.black.withAlphaComponent(0.5))) // 屏幕背景半透明遮罩
        attributes.roundCorners = .all(radius: 16) // 圆角
        attributes.border = .value(color: UIColor.gray, width: 0.5) // 边框
        attributes.positionConstraints.maxSize = .init(width: .offset(value: 20), height: .intrinsic)
        
        // 设置交互类型
        attributes.screenInteraction = .dismiss
        
        // 标题
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = UIColor.black
        titleLabel.textAlignment = .center
        subViews.append(titleLabel)
        
        // 分隔线
        let separatorLineView = UIView()
        separatorLineView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.5)
        subViews.append(separatorLineView)
        
        if message != nil {
            // 消息文本
            let messageLabel = UILabel()
            messageLabel.text = message!
            messageLabel.numberOfLines = 0
            messageLabel.textAlignment = .center
            messageLabel.font = UIFont.systemFont(ofSize: 16)
            messageLabel.textColor = UIColor.darkGray
            subViews.append(messageLabel)
        }
        
        // 确认按钮
        let confirmButton = UIButton(type: .system)
        confirmButton.setTitle(okString, for: .normal)
        confirmButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        confirmButton.setTitleColor(UIColor.white, for: .normal)
        confirmButton.backgroundColor = UIColor.blue
        confirmButton.layer.cornerRadius = 22
        confirmButton.clipsToBounds = true
        confirmButton.rx.tapGesture(configuration: { gestureRecognizer, delegate in
            delegate.touchReceptionPolicy = .custom { gestureRecognizer, touches in
                return touches.view == confirmButton
            }
            delegate.otherFailureRequirementPolicy = .custom { gestureRecognizer, otherGestureRecognizer in
                return otherGestureRecognizer is UILongPressGestureRecognizer
            }
        }).when(.ended)
            .subscribe { _ in
                SwiftEntryKit.dismiss()
                ok()
            }.disposed(by: self.disposeBag)
        subViews.append(confirmButton)
        
        // 取消按钮
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle(cancelString, for: .normal)
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        cancelButton.setTitleColor(UIColor.blue, for: .normal)
        cancelButton.backgroundColor = UIColor.init(hex: "#CCCCCC")
        cancelButton.layer.cornerRadius = 22
        cancelButton.clipsToBounds = true
        cancelButton.rx.tapGesture(configuration: { gestureRecognizer, delegate in
            delegate.touchReceptionPolicy = .custom { gestureRecognizer, touches in
                return touches.view == cancelButton
            }
            delegate.otherFailureRequirementPolicy = .custom { gestureRecognizer, otherGestureRecognizer in
                return otherGestureRecognizer is UILongPressGestureRecognizer
            }
        }).when(.ended)
            .subscribe { _ in
                SwiftEntryKit.dismiss()
                cancel()
            }.disposed(by: self.disposeBag)
        subViews.append(cancelButton)
        
        if extraString != nil {
            let extraButton = UIButton(type: .system)
            extraButton.setTitle(extraString!, for: .normal)
            extraButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            extraButton.setTitleColor(UIColor.blue, for: .normal)
            extraButton.layer.cornerRadius = 22
            extraButton.clipsToBounds = true
            extraButton.rx.tapGesture(configuration: { gestureRecognizer, delegate in
                delegate.touchReceptionPolicy = .custom { gestureRecognizer, touches in
                    return touches.view == extraButton
                }
                delegate.otherFailureRequirementPolicy = .custom { gestureRecognizer, otherGestureRecognizer in
                    return otherGestureRecognizer is UILongPressGestureRecognizer
                }
            }).when(.ended)
                .subscribe { _ in
                    SwiftEntryKit.dismiss()
                    extra?()
                }.disposed(by: self.disposeBag)
            subViews.append(extraButton)
            
            extraButton.translatesAutoresizingMaskIntoConstraints = false
            extraButton.heightAnchor.constraint(equalToConstant: 44).isActive = true // 设置按钮高度
        }

        // 垂直堆叠视图
        
        let stackView = UIStackView(arrangedSubviews: subViews)
        stackView.axis = .vertical
        stackView.spacing = 10
        
        // 添加约束
        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
        separatorLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.heightAnchor.constraint(equalToConstant: 44).isActive = true // 设置按钮高度

        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.heightAnchor.constraint(equalToConstant: 44).isActive = true // 设置按钮高度
        
        // 设置内边距
        stackView.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        stackView.isLayoutMarginsRelativeArrangement = true
        
        // 显示对话框
        SwiftEntryKit.display(entry: stackView, using: attributes)
    }
    
}
