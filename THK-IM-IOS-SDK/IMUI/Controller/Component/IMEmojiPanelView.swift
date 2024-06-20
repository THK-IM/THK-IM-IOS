//
//  IMEmojiPanelView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/10.
//

import Foundation
import UIKit
import CocoaLumberjack
import RxSwift

class IMEmojiPanelView: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    private let cellTitleId = "emoji_panel_title_cell"
    private let cellContentId = "emoji_panel_title_cell"
    private var selectIndex = IndexPath(row: 0, section: 0)
    
    private var emojiPanels = Array<IMBasePanelViewProvider>()
    
    weak var sender: IMMsgSender?
    private let disposeBag = DisposeBag()
    
    lazy var emojiTabView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumInteritemSpacing = 20
        let collectionView = UICollectionView(frame: self.frame, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundView = nil
        collectionView.backgroundColor = UIColor.clear
        collectionView.register(IMEmojiPanelTitleCell.self, forCellWithReuseIdentifier: self.cellTitleId)
        collectionView.alpha = 1
        return collectionView
    }()
    
    lazy var emojiContentView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .horizontal
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumInteritemSpacing = 0
        let collectionView = UICollectionView(frame: self.frame, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundView = nil
        collectionView.backgroundColor = UIColor.clear
        collectionView.register(IMEmojiPanelContentCell.self, forCellWithReuseIdentifier: self.cellContentId)
        collectionView.alpha = 1
        return collectionView
    }()
    
    lazy var sendView: UIImageView = {
        let view = UIImageView()
        view.image = ResourceUtils.loadImage(named: "ic_emoji_send")
        return view
    }()
    
    lazy var delView: UIImageView = {
        let view = UIImageView()
        view.image = ResourceUtils.loadImage(named: "ic_emoji_del")
        return view
    }()
    
    lazy var emojiTabContainer: UIView = {
        let view = UIView()
//        view.backgroundColor = UIColor.init(hex: "#F5F5F5")
        view.backgroundColor = IMUIManager.shared.uiResourceProvider?.inputLayoutBgColor()
        view.addSubview(self.sendView)
        view.addSubview(self.delView)
        view.addSubview(self.emojiTabView)
        return view
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.emojiTabContainer)
        self.addSubview(self.emojiContentView)
        self.emojiContentView.snp.remakeConstraints { make in
            make.left.equalToSuperview()
            make.width.equalToSuperview()
            make.top.equalToSuperview()
            make.height.equalTo(256)
        }
        self.emojiTabContainer.snp.remakeConstraints { make in
            make.left.equalToSuperview()
            make.width.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(80)
        }
        self.sendView.snp.remakeConstraints { make in
            make.size.equalTo(30)
            make.right.equalToSuperview().offset(-10)
            make.top.equalToSuperview().offset(8)
        }
        self.delView.snp.remakeConstraints { make in
            make.size.equalTo(30)
            make.right.equalToSuperview().offset(-50)
            make.top.equalToSuperview().offset(8)
        }
        self.emojiTabView.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.height.equalTo(40)
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-100)
        }
        self.delView.rx.tapGesture()
            .asObservable()
            .subscribe(onNext: { [weak self] _ in
                self?.sender?.deleteInputContent(count: 1)
            }).disposed(by: self.disposeBag)
        
        self.sendView.rx.tapGesture()
            .asObservable()
            .subscribe(onNext: { [weak self] _ in
                self?.sender?.sendInputContent()
            }).disposed(by: self.disposeBag)
    }
    
    override func layoutSubviews() {
        if self.emojiPanels.count == 0 {
            if let session = self.sender?.getSession() {
                let emojiPanels = IMUIManager.shared.getPanelProviders(session: session)
                self.emojiPanels.append(contentsOf: emojiPanels)
                self.emojiContentView.reloadData()
            }
        }
        if selectIndex.row < emojiPanels.count {
            self.emojiTabView.selectItem(at: selectIndex, animated: false, scrollPosition: .centeredHorizontally)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return emojiPanels.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.emojiTabView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellTitleId, for: indexPath)
            let tabCell = cell as! IMEmojiPanelTitleCell
            let provider = emojiPanels[indexPath.row]
            tabCell.setProvider(provider)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellContentId, for: indexPath)
            let tabCell = cell as! IMEmojiPanelContentCell
            let provider = emojiPanels[indexPath.row]
            tabCell.setProvider(sender, provider)
            return cell
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == self.emojiTabView {
            let boundSize: CGFloat = collectionView.frame.height
            return CGSize(width: boundSize, height: boundSize)
        } else {
            return collectionView.frame.size
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectIndex = indexPath
        if collectionView == self.emojiTabView {
            self.emojiContentView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        } else {
            self.emojiTabView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
    
}
