//
//  ContactViewController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit
import RxSwift

class ContactViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let contactTableView = UITableView()
    private let contactIdentifier = "table_cell_contact"
    private var contacts = [Contact]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.initContacts()
    }
    
    override func title() -> String? {
        return "Contact"
    }
    
    override func hasSearchMenu() -> Bool {
        return true
    }
    
    func setupUI() {
        let statusBarHeight = AppUtils.getStatusBarHeight()
        let navigationItemHeight = self.navigationController?.navigationBar.frame.height ?? 0
        let top = statusBarHeight + navigationItemHeight
        self.view.addSubview(contactTableView)
        self.contactTableView.backgroundColor = UIColor.white
        self.contactTableView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(top)
            make.bottom.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        self.contactTableView.dataSource = self
        self.contactTableView.delegate = self
    }
    
    func initContacts() {
        IMCoreManager.shared.contactModule.queryAllContacts()
            .subscribe(onNext: { [weak self] contacts in
                self?.contacts.append(contentsOf: contacts)
                self?.contactTableView.reloadData()
            }).disposed(by: self.disposeBag)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.contacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let contact = self.contacts[indexPath.row]
        var viewCell = tableView.dequeueReusableCell(withIdentifier: contactIdentifier)
        if (viewCell == nil) {
            viewCell = ContactTableCell(style: .default, reuseIdentifier: contactIdentifier)
        }
        (viewCell! as! ContactTableCell).setData(contact: contact)
        return viewCell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let contact = self.contacts[indexPath.row]
        IMCoreManager.shared.messageModule.getSession(contact.id, SessionType.Single.rawValue)
            .compose(RxTransformer.shared.io2Main())
            .subscribe(onNext: { session in
                IMUIManager.shared.pageRouter?.openSession(controller: self, session: session)
            }).disposed(by: self.disposeBag)
    }
}
