//
//  BaseViewController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/5.
//  Copyright © 2024 THK. All rights reserved.
//

import BadgeSwift
import JDStatusBarNotification
import ProgressHUD
import RxSwift
import SwiftEntryKit
import UIKit

open class BaseViewController: UIViewController, UIGestureRecognizerDelegate {

    public let menuItemTagAdd = "add"
    public let menuItemTagSearch = "search"
    public let menuSize = CGSize(width: 30, height: 30)

    public let disposeBag = DisposeBag()
    
    private let _defaultTitleBarLayout = TitlebarLayout()
    private lazy var _titleBarLayout: UIView = {
        let v = UIView()
        v.addSubview(self.titleBarLayout)
        let top = AppUtils.getStatusBarHeight()
        self.titleBarLayout.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(top)
            make.left.right.bottom.equalToSuperview()
        }
        self.titleBarLayout.setTapAction { [weak self] action in
            if action == "back" {
                self?.onBackItemTapped()
            } else if action == "add" {
                self?.onMenuClick(menu: "add")
            } else if action == "search" {
                self?.onMenuClick(menu: "search")
            }
        }
        return v
    }()
    
    open var titleBarLayout: TitlebarLayout {
        return _defaultTitleBarLayout
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = true
        if self.hasTitlebar() {
            self.initTitleBarLayout()
        }
        let tapGesture = UITapGestureRecognizer(
            target: self, action: #selector(self.viewTouched))
        tapGesture.cancelsTouchesInView = false  // 这样不会阻止其他控件接收 touch 事件
        self.view.addGestureRecognizer(tapGesture)
    }

    open func hasTitlebar() -> Bool {
        return self.navigationController != nil
    }

    open func initTitleBarLayout() {
        let height = self.getTitleBarHeight()
        self.view.addSubview(self._titleBarLayout)
        self._titleBarLayout.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(height)
        }
        self.renderTitleBar()
    }

    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        self.view.bringSubviewToFront(self._titleBarLayout)
    }

    open func renderTitleBar() {
        self.titleBarLayout.setTitle(self.title())
        if self.canSwipeBack() {
            let backImage = self.backIcon()?.withRenderingMode(.alwaysOriginal)
            self.titleBarLayout.setBackItem(backImage)
        }
        if self.hasAddMenu() {
            self.titleBarLayout.setAddRightItem(
                self.menuImages(menu: menuItemTagAdd))
        }
        if self.hasSearchMenu() {
            self.titleBarLayout.setSearchItem(
                self.menuImages(menu: menuItemTagSearch))
        }
    }

    open func onBackItemTapped() {
        if self.navigationController != nil {
            self.navigationController?.popViewController(animated: true)
        } else {
            self.dismiss(animated: true)
        }
    }

    open func setTitle(title: String) {
        self.titleBarLayout.setTitle(title)
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.interactivePopGestureRecognizer?.delegate =
            self
    }

    @objc open func viewTouched() {
        self.view.endEditing(true)
    }

    open func backIcon() -> UIImage? {
        return ResourceUtils.loadImage(named: "ic_titlebar_back")?
            .withTintColor(
                IMUIManager.shared.uiResourceProvider?.inputTextColor()
                    ?? UIColor.init(hex: "333333"))
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
        if menu == menuItemTagAdd {
            image = ResourceUtils.loadImage(named: "ic_titlebar_add")?
                .withTintColor(
                    IMUIManager.shared.uiResourceProvider?.inputTextColor()
                        ?? UIColor.init(hex: "333333"))
        } else if menu == menuItemTagSearch {
            image = ResourceUtils.loadImage(named: "ic_titlebar_search")?
                .withTintColor(
                    IMUIManager.shared.uiResourceProvider?.inputTextColor()
                        ?? UIColor.init(hex: "333333"))
        }
        if image == nil {
            return image
        }
        return image!.scaledToSize(menuSize)
    }

    open func onMenuClick(menu: String) {

    }

    open func showError(_ err: Error) {
        if let codeMessageErr = err as? CodeMessageError {
            showToast(codeMessageErr.message)
        } else {
            showToast(err.localizedDescription)
        }
    }

    public func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch
    ) -> Bool {
        return true
    }

    public func gestureRecognizerShouldBegin(
        _ gestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return self.canSwipeBack()
    }

    open func canSwipeBack() -> Bool {
        return self.navigationController?.children.count ?? 0 > 1
    }

    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask
    {
        return .portrait
    }

    open func getTitleBarHeight() -> CGFloat {
        var navigationBarHeight = 0.0
        if let navigationController = self.navigationController {
            navigationBarHeight +=
                navigationController.navigationBar.frame.height
        }
        return navigationBarHeight + AppUtils.getStatusBarHeight()
    }

    // 显示自定义的警告对话框
    open func showDialog(
        title: String, message: String?, okString: String, cancelString: String,
        extraString: String?,
        _ ok: @escaping () -> Void, _ cancel: @escaping () -> Void,
        _ extra: (() -> Void)?
    ) {
        var subViews = [UIView]()
        // 定义外观属性
        var attributes = EKAttributes.centerFloat
        attributes.windowLevel = .normal
        attributes.hapticFeedbackType = .success
        attributes.displayDuration = .infinity  // 对话框会一直显示直到用户交互
        attributes.entryBackground = .color(color: EKColor(UIColor.white))  // 背景颜色
        attributes.shadow = .active(
            with: .init(
                color: EKColor(UIColor.black.withAlphaComponent(0.3)),
                opacity: 1, radius: 10))
        attributes.screenBackground = .color(
            color: EKColor(UIColor.black.withAlphaComponent(0.5)))  // 屏幕背景半透明遮罩
        attributes.roundCorners = .all(radius: 16)  // 圆角
        attributes.border = .value(color: UIColor.gray, width: 0.5)  // 边框
        attributes.positionConstraints.maxSize = .init(
            width: .offset(value: 20), height: .intrinsic)

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
        separatorLineView.backgroundColor = UIColor.lightGray
            .withAlphaComponent(0.5)
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
        confirmButton.titleLabel?.font = UIFont.systemFont(
            ofSize: 16, weight: .semibold)
        confirmButton.setTitleColor(UIColor.white, for: .normal)
        confirmButton.backgroundColor = UIColor.blue
        confirmButton.layer.cornerRadius = 22
        confirmButton.clipsToBounds = true
        confirmButton.rx.tapGesture(configuration: {
            gestureRecognizer, delegate in
            delegate.touchReceptionPolicy = .custom {
                gestureRecognizer, touches in
                return touches.view == confirmButton
            }
            delegate.otherFailureRequirementPolicy = .custom {
                gestureRecognizer, otherGestureRecognizer in
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
        cancelButton.titleLabel?.font = UIFont.systemFont(
            ofSize: 16, weight: .medium)
        cancelButton.setTitleColor(UIColor.blue, for: .normal)
        cancelButton.backgroundColor = UIColor.init(hex: "#CCCCCC")
        cancelButton.layer.cornerRadius = 22
        cancelButton.clipsToBounds = true
        cancelButton.rx.tapGesture(configuration: {
            gestureRecognizer, delegate in
            delegate.touchReceptionPolicy = .custom {
                gestureRecognizer, touches in
                return touches.view == cancelButton
            }
            delegate.otherFailureRequirementPolicy = .custom {
                gestureRecognizer, otherGestureRecognizer in
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
            extraButton.titleLabel?.font = UIFont.systemFont(
                ofSize: 16, weight: .medium)
            extraButton.setTitleColor(UIColor.blue, for: .normal)
            extraButton.layer.cornerRadius = 22
            extraButton.clipsToBounds = true
            extraButton.rx.tapGesture(configuration: {
                gestureRecognizer, delegate in
                delegate.touchReceptionPolicy = .custom {
                    gestureRecognizer, touches in
                    return touches.view == extraButton
                }
                delegate.otherFailureRequirementPolicy = .custom {
                    gestureRecognizer, otherGestureRecognizer in
                    return otherGestureRecognizer
                        is UILongPressGestureRecognizer
                }
            }).when(.ended)
                .subscribe { _ in
                    SwiftEntryKit.dismiss()
                    extra?()
                }.disposed(by: self.disposeBag)
            subViews.append(extraButton)

            extraButton.translatesAutoresizingMaskIntoConstraints = false
            extraButton.heightAnchor.constraint(equalToConstant: 44).isActive =
                true  // 设置按钮高度
        }

        // 垂直堆叠视图

        let stackView = UIStackView(arrangedSubviews: subViews)
        stackView.axis = .vertical
        stackView.spacing = 10

        // 添加约束
        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
        separatorLineView.heightAnchor.constraint(equalToConstant: 1).isActive =
            true

        confirmButton.translatesAutoresizingMaskIntoConstraints = false
        confirmButton.heightAnchor.constraint(equalToConstant: 44).isActive =
            true  // 设置按钮高度

        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.heightAnchor.constraint(equalToConstant: 44).isActive =
            true  // 设置按钮高度

        // 设置内边距
        stackView.layoutMargins = UIEdgeInsets(
            top: 20, left: 20, bottom: 20, right: 20)
        stackView.isLayoutMarginsRelativeArrangement = true

        // 显示对话框
        SwiftEntryKit.display(entry: stackView, using: attributes)
    }

    open func showLoading(text: String? = nil, _ interaction: Bool = false) {
        DispatchQueue.main.async {
            ProgressHUD.animate(
                text, .horizontalBarScaling, interaction: interaction)
        }
    }

    open func dismissLoading() {
        DispatchQueue.main.async {
            ProgressHUD.dismiss()
        }
    }

    open func showToast(_ toast: String, _ success: Bool = true) {
        DispatchQueue.main.async {
            NotificationPresenter.shared.present(toast)
            NotificationPresenter.shared.dismiss(after: 1)
        }
    }

    deinit {
        print("deinit \(self.description)")
    }
}
