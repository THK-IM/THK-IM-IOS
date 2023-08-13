//
//  IMEmojiView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/10.
//

import Foundation
import UIKit
import Tabman
import Pageboy

class IMEmojiController: TabmanViewController, PageboyViewControllerDataSource, TMBarDataSource {
    
    weak var sender: IMMsgSender?
    private let providers = IMUIManager.shared.getEmojiControllerProviders()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dataSource = self
        let bar = TMBar.TabBar()
        bar.layout.alignment = .leading
        bar.layout.transitionStyle = .none
        bar.backgroundColor = UIColor.init(hex: "eaeaea")
        let width = 40 * providers.count
        let right = UIScreen.main.bounds.width - CGFloat(width)
        if right > 0 {
            bar.layout.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: right)
        }
        addBar(bar, dataSource: self, at: .top)
    }
    
    func numberOfViewControllers(in pageboyViewController: PageboyViewController) -> Int {
        return providers.count
    }
    
    func viewController(for pageboyViewController: PageboyViewController,
                        at index: PageboyViewController.PageIndex) -> UIViewController? {
        return providers[index].controller(sender: self.sender)
    }
    
    func defaultPage(for pageboyViewController: PageboyViewController) -> PageboyViewController.Page? {
        return nil
    }
    
    func barItem(for bar: TMBar, at index: Int) -> TMBarItemable {
        let image = providers[index].icon(selected: false)
        return TMBarItem(image: image)
    }
}

