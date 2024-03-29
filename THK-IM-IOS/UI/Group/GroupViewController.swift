//
//  GroupViewController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/11.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit
import RxSwift

class GroupViewController: BaseViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, ContactChooseDelegate {
    
    static func open(_ uiViewController: UIViewController, _ group: Group?, _ mode: Int = 0) {
        let groupController = GroupViewController()
        groupController.group = group
        groupController.mode = mode
        groupController.hidesBottomBarWhenPushed = true
        uiViewController.navigationController?.pushViewController(groupController, animated: true)
    }
    
    private lazy var groupNameLayout: UIView = {
        let view = UIView()
        view.addSubview(self.groupNameView)
        view.addSubview(self.groupNameTextView)
        self.groupNameView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(10)
            make.height.equalTo(24)
            make.width.greaterThanOrEqualTo(40)
        }
        self.groupNameTextView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-10)
            make.height.equalTo(24)
            make.width.greaterThanOrEqualTo(40)
            make.width.lessThanOrEqualTo(240)
        }
        return view
    }()
    private lazy var groupNameView: UILabel = {
        let view = UILabel()
        view.textColor = UIColor.init(hex: "444444")
        view.font = UIFont.systemFont(ofSize: 14)
        view.text = "群名称"
        return view
    }()
    private lazy var groupNameTextView: UITextField = {
        let view = UITextField()
        view.textColor = UIColor.init(hex: "222222")
        view.font = UIFont.systemFont(ofSize: 14)
        return view
    }()
    
    private lazy var groupAvatarLayout: UIView = {
        let view = UIView()
        view.addSubview(self.groupAvatarView)
        view.addSubview(self.groupAvatarImageView)
        self.groupAvatarView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(10)
            make.height.equalTo(24)
            make.width.greaterThanOrEqualTo(40)
        }
        self.groupAvatarImageView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-10)
            make.height.equalTo(48)
            make.width.equalTo(48)
        }
        return view
    }()
    private lazy var groupAvatarView: UILabel = {
        let view = UILabel()
        view.textColor = UIColor.init(hex: "444444")
        view.font = UIFont.systemFont(ofSize: 14)
        view.text = "群头像"
        return view
    }()
    private lazy var groupAvatarImageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleToFill
        return view
    }()
    
    private lazy var groupAnnounceLayout: UIView = {
        let view = UIView()
        view.addSubview(self.groupAnnounceView)
        self.groupAnnounceView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.left.equalToSuperview().offset(10)
            make.height.equalTo(24)
            make.right.equalToSuperview().offset(-10)
        }
        view.addSubview(groupAnnounceTextView)
        self.groupAnnounceTextView.snp.makeConstraints { make in
            make.top.equalTo(self.groupAnnounceView.snp.bottom)
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
            make.bottom.equalToSuperview()
        }
        return view
    }()
    private lazy var groupAnnounceView: UILabel = {
        let view = UILabel()
        view.textColor = UIColor.init(hex: "444444")
        view.font = UIFont.systemFont(ofSize: 14)
        view.text = "群公告(0/100)"
        return view
    }()
    private lazy var groupAnnounceTextView: UITextView = {
        let view = UITextView()
        view.textColor = UIColor.init(hex: "222222")
        view.text = "在这里输入群公告"
        view.font = UIFont.systemFont(ofSize: 14)
        return view
    }()
    
    private lazy var groupMemberLayout: UIView = {
        let view = UIView()
        view.addSubview(self.groupMemberView)
        view.addSubview(self.groupMemberArrowView)
        self.groupMemberView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(10)
            make.height.equalTo(24)
            make.width.equalTo(60)
        }
        self.groupMemberArrowView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-10)
            make.height.equalTo(20)
            make.width.equalTo(20)
        }
        return view
    }()
    private lazy var groupMemberView: UILabel = {
        let view = UILabel()
        view.textColor = UIColor.init(hex: "444444")
        view.font = UIFont.systemFont(ofSize: 14)
        view.text = "群成员"
        return view
    }()
    private lazy var groupMemberArrowView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "ic_arrow_right")
        return view
    }()
    
    private lazy var groupMembersView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumInteritemSpacing = 0
        let collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundView = nil
        collectionView.backgroundColor = UIColor.clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(
            SessionMemberCell.self,
            forCellWithReuseIdentifier: NSStringFromClass(SessionMemberCell.self)
        )
        collectionView.alpha = 1
        return collectionView
    }()
    
    var mode: Int = 0 // 0 创建群 1查看群
    var group: Group? = nil
    var members = [SessionMember]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if (mode == 0) {
            self.setTitle(title: "创建群")
        } else {
            self.setTitle(title: group!.name)
        }
        self.view.backgroundColor = UIColor.init(hex: "dcdcdc")
        self.setupUI()
    }
    
    override func hasAddMenu() -> Bool {
        if (mode == 0) {
            return true
        } else {
            return false
        }
    }
    
    override func hasSearchMenu() -> Bool {
        return false
    }
    
    override func menuImages(menu: String) -> UIImage? {
        if (menu == "add") {
            return UIImage(named: "ic_choose")?.scaledToSize(CGSize(width: 24, height: 24))
        }
        return super.menuImages(menu: menu)
    }
    
    override func onMenuClick(menu: String) {
        if (menu == "add") {
            if (mode == 0) {
                self.createGroup()
            }
        } else if (menu == "click") {
            
        }
    }
    
    private func setupUI() {
        let statusHeight = AppUtils.getStatusBarHeight()
        let navigationItemHeight = self.navigationController?.navigationBar.frame.height ?? 0
        let top = statusHeight + navigationItemHeight
        self.view.addSubview(self.groupNameLayout)
        self.groupNameLayout.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(top)
            make.height.equalTo(60)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        
        self.view.addSubview(self.groupAvatarLayout)
        self.groupAvatarLayout.snp.makeConstraints { make in
            make.top.equalTo(self.groupNameLayout.snp.bottom)
            make.height.equalTo(mode == 0 ? 0: 60)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        
        self.view.addSubview(self.groupAnnounceLayout)
        self.groupAnnounceLayout.snp.makeConstraints { make in
            make.top.equalTo(self.groupAvatarLayout.snp.bottom)
            make.height.equalTo(150)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }

        self.view.addSubview(self.groupMemberLayout)
        self.groupMemberLayout.snp.makeConstraints { make in
            make.top.equalTo(self.groupAnnounceLayout.snp.bottom)
            make.height.equalTo(60)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        self.view.addSubview(self.groupMembersView)
        self.groupMembersView.snp.makeConstraints { make in
            make.top.equalTo(self.groupMemberLayout.snp.bottom)
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
            make.bottom.equalToSuperview()
        }
        
        self.setupNameLayout()
        self.setupAvatarLayout()
        self.setupAnnounceLayout()
        self.setupMembersLayout()
        
    }
    
    private func setupNameLayout() {
        if (mode == 0) {
            DispatchQueue.main.asyncAfter(deadline: .now()+0.5, execute: { [weak self] in
                    self?.groupNameTextView.becomeFirstResponder()
            })
        } else {
            self.groupNameTextView.text = group?.name ?? ""
        }
    }
    
    private func setupAvatarLayout() {
        if (mode == 0) {
            self.groupAvatarLayout.isHidden = true
        } else {
            self.groupAvatarLayout.isHidden = false
            self.groupAvatarImageView.renderImageByUrlWithCorner(url: group?.avatar ?? "", radius: 10)
        }
    }
    
    private func setupAnnounceLayout() {
        if (mode == 0) {
            
        } else {
            self.groupAnnounceTextView.text = group?.announce ?? ""
        }
    }
    
    private func setupMembersLayout() {
        if (mode == 0) {
            let tapGesture = UITapGestureRecognizer()
            tapGesture.rx.event.asObservable()
                .subscribe({ [weak self] _ in
                    guard let sf = self else {
                        return
                    }
                    ContactViewController.openChooseContact(sf, delegate: sf)
                }).disposed(by: self.disposeBag)
            self.groupMemberLayout.addGestureRecognizer(tapGesture)
        } else {
            guard let sessionId = group?.sessionId else {
                return
            }
            IMCoreManager.shared.messageModule.querySessionMembers(sessionId, false)
                .compose(RxTransformer.shared.io2Main())
                .subscribe(onNext: { [weak self] sessionMembers in
                    self?.members = sessionMembers
                    self?.groupMembersView.reloadData()
                }).disposed(by: self.disposeBag)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return members.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {        
        let boundSize: CGFloat = UIScreen.main.bounds.width / 5 - 4
        return CGSize(width: boundSize, height: boundSize)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: NSStringFromClass(SessionMemberCell.self),
            for: indexPath
        ) as! SessionMemberCell
        let member = self.members[indexPath.row]
        cell.setMemberId(id: member.userId)
        return cell
    }
    
    private func createGroup() {
        guard let groupName = groupNameTextView.text else {
            showToast("请输入群名称")
            return
        }
        let groupAnnounce = groupAnnounceTextView.text ?? ""
        guard let uId = DataRepository.shared.getUserId() else {
            return
        }
        var memberIds = Set<Int64>()
        for m in members {
            if (m.userId > 0) {
                memberIds.insert(m.userId)
            }
        }
        if (memberIds.count <= 0) {
            showToast("请选择群成员")
            return
        }
        
        let req = CreateGroupVo(
            uId: uId,
            members: memberIds,
            groupName: groupName,
            groupAnnounce: groupAnnounce,
            groupType: SessionType.Group.rawValue
        )
        DataRepository.shared.groupApi.rx
            .request(.createGroup(req))
            .asObservable()
            .compose(RxTransformer.shared.response2Bean(GroupVo.self))
            .compose(RxTransformer.shared.io2Main())
            .flatMap({ groupVo -> Observable<Group> in
                let group = groupVo.toGroup()
                try IMCoreManager.shared.database.groupDao().insertOrReplace([group])
                return Observable.just(group)
            })
            .flatMap({ group -> Observable<Session> in
                return IMCoreManager.shared.messageModule.getSession(group.sessionId)
            })
            .subscribe(onNext: { [weak self] session in
                guard let sf = self else {
                    return
                }
                IMUIManager.shared.pageRouter?.openSession(controller: sf, session: session)
            }).disposed(by: self.disposeBag)
        
    }
    
    func onContactChoose(ids: Set<Int64>) {
        self.members.removeAll()
        for id in ids {
            self.members.append(SessionMember(userId: id))
        }
        self.groupMembersView.reloadData()
    }
    
    
    
    
}
