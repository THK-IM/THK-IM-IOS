//
//  IMAtSessionMemberController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/20.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit
import RxSwift

class IMAtSessionMemberController: UIViewController, UITableViewDelegate, UITableViewDataSource, UIViewControllerTransitioningDelegate {
    
    private let disposeBag = DisposeBag()
    private let titleView = UILabel()
    private let memberTableView = UITableView()
    private let sessionMemberIdentifier = "table_cell_session_member"
    var session: Session? = nil
    private var sessionMembers = [SessionMember]()
    weak var delegate: IMSessionMemberAtDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.initSessionMembers()
    }
    
    func setupUI() {
        self.view.backgroundColor = UIColor.white
        self.view.addSubview(self.titleView)
        self.titleView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(30)
        }
        self.titleView.text = "选择提醒的人"
        self.titleView.font = UIFont.systemFont(ofSize: 18)
        self.titleView.textAlignment = .center
        self.titleView.textColor = UIColor.init(hex: "#333333")
        
        self.view.addSubview(memberTableView)
        self.memberTableView.separatorStyle = .none
        self.memberTableView.backgroundColor = UIColor.white
        self.memberTableView.snp.makeConstraints { [weak self] make in
            guard let sf = self else {
                return
            }
            make.top.equalTo(sf.titleView.snp.bottom)
            make.bottom.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        self.memberTableView.dataSource = self
        self.memberTableView.delegate = self
    }
    
    func initSessionMembers() {
        guard let session = self.session else {
            return 
        }
        IMCoreManager.shared.messageModule.querySessionMembers(session.id)
            .compose(RxTransformer.shared.io2Main())
            .subscribe(onNext: { [weak self] sessionMembers in
                self?.sessionMembers.append(contentsOf: sessionMembers)
                self?.memberTableView.reloadData()
            }).disposed(by: self.disposeBag)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sessionMembers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sessionMember = self.sessionMembers[indexPath.row]
        var viewCell = tableView.dequeueReusableCell(withIdentifier: sessionMemberIdentifier)
        if (viewCell == nil) {
            viewCell = IMSessionMemberCell(style: .default, reuseIdentifier: sessionMemberIdentifier)
        }
        (viewCell! as! IMSessionMemberCell).setData(sessionMember: sessionMember)
        return viewCell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: true)
        if let cell = tableView.cellForRow(at: indexPath) as? IMSessionMemberCell {
            if let user = cell.getUser() {
                let sessionMember = self.sessionMembers[indexPath.row]
                self.delegate?.onSessionMemberAt(sessionMember: sessionMember, user: user)
            }
        }
    }
    
    func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        return BottomPresentationController(presentedViewController: presented, presenting: presenting)
    }
}

