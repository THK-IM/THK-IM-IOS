//
//  MainViewController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit
import RxSwift


class MainViewController: UITabBarController {
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        
        self.view.backgroundColor = UIColor.init(hex: "dddddd")
        
        self.viewControllers = [
            UINavigationController(rootViewController: SessionTabViewController()),
            UINavigationController(rootViewController: ContactTabViewController()),
            UINavigationController(rootViewController: GroupTabViewController()),
            UINavigationController(rootViewController: MineTabViewController())
        ]
        
        self.tabBar.backgroundColor = UIColor.init(hex: "dddddd")
        self.tabBar.tintColor = UIColor.init(hex: "1011D0")
        self.tabBar.barTintColor = UIColor.white
        
        let imageMessage = UIImage(named: "ic_tab_message")?.scaledToSize(CGSize(width: 30, height: 30))
        let itemMessage = UITabBarItem(title: "message", image: imageMessage, selectedImage: imageMessage)
        
        let imageContact = UIImage(named: "ic_tab_contact")?.scaledToSize(CGSize(width: 30, height: 30))
        let itemContact = UITabBarItem(title: "contact", image: imageContact, selectedImage: imageContact)
        
        let imageGroup = UIImage(named: "ic_tab_group")?.scaledToSize(CGSize(width: 30, height: 30))
        let itemGroup = UITabBarItem(title: "group", image: imageGroup, selectedImage: imageGroup)
        
        let imageMine = UIImage(named: "ic_tab_mine")?.scaledToSize(CGSize(width: 30, height: 30))
        let itemMine = UITabBarItem(title: "mine", image: imageMine, selectedImage: imageMine)
        
        self.viewControllers?[0].tabBarItem = itemMessage
        self.viewControllers?[1].tabBarItem = itemContact
        self.viewControllers?[2].tabBarItem = itemGroup
        self.viewControllers?[3].tabBarItem = itemMine
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        
    }
    
    private func updateNewMessageCount(_ count: Int) {
        if count <= 0 {
            self.tabBar.items?[0].badgeValue = nil
        } else if count < 99 {
            self.tabBar.items?[0].badgeValue = "\(count)"
        } else {
            self.tabBar.items?[0].badgeValue = "99+"
        }
    }
    
}
