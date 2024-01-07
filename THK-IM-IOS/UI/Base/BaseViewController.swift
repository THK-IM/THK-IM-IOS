//
//  BaseViewController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/5.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit
import RxSwift

open class BaseViewController: UIViewController {
    
    let disposeBag = DisposeBag()
    
    override open func viewDidLoad() {
        if let title = title() {
            setTitle(title: title)
        }
        var images = [UIImage?]()
        var actions = [Selector?]()
        if hasAddMenu() {
            images.append(menuImages(menu: "add"))
            actions.append(#selector(addTapped))
        }
        if hasSearchMenu() {
            images.append(menuImages(menu: "search"))
            actions.append(#selector(searchTapped))
        }
        setRightItems(images: images, actions: actions)
    }
    
    open func showLoading(text: String) {
        
    }
    
    open func dismissLoading() {
        
    }
    
    open func showToast() {
        
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
        if (menu == "add") {
            image = UIImage(named: "ic_titlebar_add")
        } else if (menu == "search") {
            image = UIImage(named: "ic_titlebar_search")
        }
        if image == nil {
            return image
        }
        return image!.scaledToSize(CGSize(width: 24, height: 24))
    }
    
    open func onMenuClick(menu: String) {
        
    }
    
    
    @objc func addTapped() {
        onMenuClick(menu: "add")
    }
    
    @objc func searchTapped() {
        onMenuClick(menu: "search")
    }
    
}
