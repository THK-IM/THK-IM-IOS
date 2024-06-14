//
//  ContactListViewController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/13.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit

class ContactViewController: BaseViewController, UITableViewDelegate, UITableViewDataSource {
    
    static func openChooseContact(_ controller: UIViewController, delegate: ContactChooseDelegate?) {
        let vc = ContactViewController()
        vc.mode = 1
        vc.delegate = delegate
        controller.navigationController?.pushViewController(vc, animated: true)
    }
    
    private let contactTableView = UITableView()
    private let contactIdentifier = "table_cell_contact"
    private var contacts = [Contact]()
    private var mode = 0 // 0 正常显示联系人 1 选择联系人
    private var selectIds = Set<Int64>()
    private weak var delegate: ContactChooseDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.initContacts()
    }
    
    override func title() -> String? {
        if (mode == 0) {
            return "Contact"
        } else {
            return "Choose Contact"
        }
    }
    
    override func menuImages(menu: String) -> UIImage? {
        if (mode == 1) {
            if (menu == "search") {
                return UIImage(named: "ic_choose")?.scaledToSize(CGSize(width: 24, height: 24))
            }
        }
        return super.menuImages(menu: menu)
    }
    
    override func hasSearchMenu() -> Bool {
        return true
    }
    
    override func onMenuClick(menu: String) {
        if (mode == 1) {
            self.delegate?.onContactChoose(ids: selectIds)
            self.navigationController?.popViewController(animated: true)
        } else {
            SearchViewController.open(self, 1)
        }
    }
    
    func setupUI() {
        let statusBarHeight = AppUtils.getStatusBarHeight()
        let navigationItemHeight = self.navigationController?.navigationBar.frame.height ?? 0
        let top = statusBarHeight + navigationItemHeight
        self.view.addSubview(contactTableView)
        self.contactTableView.separatorStyle = .none
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
            .compose(RxTransformer.shared.io2Main())
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
        let chooseOn = selectIds.contains(contact.id)
        (viewCell! as! ContactTableCell).setData(contact: contact, chooseOn)
        return viewCell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let contact = self.contacts[indexPath.row]
        if (mode == 0) {
            IMCoreManager.shared.messageModule.getSession(contact.id, SessionType.Single.rawValue)
                .compose(RxTransformer.shared.io2Main())
                .subscribe(onNext: { session in
                    if (session.id > 0) {
                        IMUIManager.shared.pageRouter?.openSession(controller: self, session: session)
                    }
                }).disposed(by: self.disposeBag)
        } else if (mode == 1) {
            let chooseOn = selectIds.contains(contact.id)
            if (chooseOn) {
                selectIds.remove(contact.id)
            } else {
                selectIds.insert(contact.id)
            }
            let cell = tableView.cellForRow(at: indexPath) as! ContactTableCell
            cell.setData(contact: contact, !chooseOn)
        }
    }
}
