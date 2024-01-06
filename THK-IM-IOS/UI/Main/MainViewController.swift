//
//  MainViewController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit


class MainViewController: UITabBarController {
    
    override func viewDidLoad() {
        
        self.view.backgroundColor = UIColor.init(hex: "dddddd")
        
        self.viewControllers = [
            UINavigationController(rootViewController: SessionViewController()),
            UINavigationController(rootViewController: ContactViewController()),
            UINavigationController(rootViewController: GroupViewController()),
            UINavigationController(rootViewController: MineViewController())
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
        
//        let titleView = UILabel(frame: CGRect(x: 0, y: 0, width: 80, height: 20))
//        titleView.text = "Message"
//        titleView.backgroundColor = UIColor.red
//        self.navigationItem.titleView = titleView
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
    }
    
}
