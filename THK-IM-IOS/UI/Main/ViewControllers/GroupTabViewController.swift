//
//  GroupTabViewController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit

class GroupTabViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let groupTableView = UITableView()
    private let contactIdentifier = "table_cell_group"
    private var groups = [Group]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func title() -> String? {
        return "Group"
    }
    
    
    override func hasSearchMenu() -> Bool {
        return true
    }
    
    override func hasAddMenu() -> Bool {
        return true
    }
    
    override func onMenuClick(menu: String) {
        if (menu == "add") {
            GroupViewController.open(self, nil)
        }
    }
    
    
    func setupUI() {
        let statusBarHeight = AppUtils.getStatusBarHeight()
        let navigationItemHeight = self.navigationController?.navigationBar.frame.height ?? 0
        let top = statusBarHeight + navigationItemHeight
        self.view.addSubview(groupTableView)
        self.groupTableView.backgroundColor = UIColor.white
        self.groupTableView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(top)
            make.bottom.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        self.groupTableView.dataSource = self
        self.groupTableView.delegate = self
        
        self.initGroups()
    }
    
    func initGroups() {
        IMCoreManager.shared.groupModule.queryAllGroups()
            .subscribe(onNext: { [weak self] groups in
                self?.groups.append(contentsOf: groups)
                self?.groupTableView.reloadData()
            }).disposed(by: self.disposeBag)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.groups.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let group = self.groups[indexPath.row]
        var viewCell = tableView.dequeueReusableCell(withIdentifier: contactIdentifier)
        if (viewCell == nil) {
            viewCell = GroupTableCell(style: .default, reuseIdentifier: contactIdentifier)
        }
        (viewCell! as! GroupTableCell).setData(group: group)
        return viewCell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        let group = self.groups[indexPath.row]
        IMCoreManager.shared.messageModule.getSession(group.sessionId)
            .compose(RxTransformer.shared.io2Main())
            .subscribe(onNext: { session in
                IMUIManager.shared.pageRouter?.openSession(controller: self, session: session)
            }).disposed(by: self.disposeBag)
    }
}
