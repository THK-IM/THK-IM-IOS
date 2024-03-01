//
//  IMEmojiPanelView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/10.
//

import Foundation
import UIKit
import CocoaLumberjack

class IMEmojiPanelView: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    private let cellTitleId = "emoji_panel_title_cell"
    private let cellContentId = "emoji_panel_title_cell"
    
    weak var sender: IMMsgSender?
    
    lazy var emojiTitleView: UICollectionView = {
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
        collectionView.isPagingEnabled = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundView = nil
        collectionView.backgroundColor = UIColor.clear
        collectionView.register(IMEmojiPanelContentCell.self, forCellWithReuseIdentifier: self.cellContentId)
        collectionView.alpha = 1
        return collectionView
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.emojiTitleView)
        self.addSubview(self.emojiContentView)
    }
    
    override func layoutSubviews() {
        self.emojiTitleView.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-10)
            make.top.equalToSuperview()
            make.height.equalTo(40)
        }
        self.emojiContentView.snp.remakeConstraints { [weak self] make in
            guard let sf = self else {
                return
            }
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            make.top.equalTo(sf.emojiTitleView.snp.bottom)
        }
        if (IMUIManager.shared.getPanelProviders().count > 0) {
            let view = IMUIManager.shared.getPanelProviders()[0].contentView(sender: self.sender)
            self.emojiContentView.addSubview(view)
            view.snp.remakeConstraints {make in
                make.edges.equalToSuperview()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return IMUIManager.shared.getPanelProviders().count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.emojiTitleView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellTitleId, for: indexPath)
            let tabCell = cell as! IMEmojiPanelTitleCell
            let provider = IMUIManager.shared.getPanelProviders()[indexPath.row]
            tabCell.setProvider(provider)
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellContentId, for: indexPath)
            let tabCell = cell as! IMEmojiPanelContentCell
            let provider = IMUIManager.shared.getPanelProviders()[indexPath.row]
            tabCell.setProvider(sender, provider)
            return cell
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == self.emojiTitleView {
            let boundSize: CGFloat = collectionView.frame.height
            return CGSize(width: boundSize, height: boundSize)
        } else {
            return collectionView.frame.size
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == self.emojiTitleView {
            self.emojiContentView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        } else {
            self.emojiTitleView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
    
}
