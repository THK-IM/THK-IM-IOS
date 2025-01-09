//
//  IMAtSessionMemberController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/20.
//  Copyright © 2024 THK. All rights reserved.
//

import RxSwift
import UIKit

class IMAtSessionMemberController: UIViewController, UITableViewDelegate, UITableViewDataSource,
    UIViewControllerTransitioningDelegate
{

    private let disposeBag = DisposeBag()
    private let titleView = UILabel()
    private let memberTableView = UITableView()
    private let sessionMemberIdentifier = "table_cell_session_member"
    private var memberMap = [(User, SessionMember?)]()
    var session: Session? = nil
    weak var delegate: IMSessionMemberAtDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        self.fetchSessionMembers()
    }

    private func setupUI() {
        self.view.backgroundColor = UIColor.white
        self.view.addSubview(self.titleView)
        self.titleView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(30)
        }
        self.titleView.text = ResourceUtils.loadString("choose_at_people", comment: "")
        self.titleView.font = UIFont.boldSystemFont(ofSize: 18)
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

    private func fetchSessionMembers() {
        guard let sessionId = self.session?.id else {
            return
        }
        IMCoreManager.shared.messageModule.querySessionMembers(sessionId, false)
            .flatMap({ members in
                var newMembers = [SessionMember]()
                for m in members {
                    if m.deleted == 0 {
                        newMembers.append(m)
                    }
                }
                return Observable.just(newMembers)
            })
            .flatMap { members in
                var ids = Set<Int64>()
                for m in members {
                    ids.insert(m.userId)
                }
                return IMCoreManager.shared.userModule.queryUsers(ids: ids)
                    .flatMap { userMap in
                        var memberMap = [Int64: (User, SessionMember?)]()
                        for (k, v) in userMap {
                            var member: SessionMember? = nil
                            for m in members {
                                if m.userId == k {
                                    member = m
                                    break
                                }
                            }
                            memberMap[k] = (v, member)
                        }
                        return Observable.just(memberMap)
                    }
            }.compose(RxTransformer.shared.io2Main())
            .subscribe(onNext: { [weak self] map in
                self?.updateSessionMember(map)
            }).disposed(by: self.disposeBag)
    }

    private func updateSessionMember(_ map: [Int64: (User, SessionMember?)]) {
        self.memberMap.append(contentsOf: map.values)
        if let session = self.session {
            if let canAtAll = IMUIManager.shared.uiResourceProvider?.canAtAll(session) {
                if canAtAll {
                    self.memberMap.append((User.all, nil))
                }
            }
        }
        self.memberTableView.reloadData()
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.memberMap.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let member = self.memberMap[indexPath.row]
        var viewCell = tableView.dequeueReusableCell(withIdentifier: sessionMemberIdentifier)
        if viewCell == nil {
            viewCell = IMSessionMemberCell(
                style: .default, reuseIdentifier: sessionMemberIdentifier)
        }
        (viewCell! as! IMSessionMemberCell).setData(memberInfo: member)
        return viewCell!
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: true)
        let member = self.memberMap[indexPath.row]
        self.delegate?.onSessionMemberAt(member)
    }

    func presentationController(
        forPresented presented: UIViewController, presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        return BottomPresentationController(
            presentedViewController: presented, presenting: presenting)
    }
}
