//
//  UnicodeEmojiUIController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/10.
//

import Foundation
import UIKit
import RxSwift

open class IMUnicodeEmojiPanelView: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    private let cellId = "unicode_emoji_cell_id"
    private let countOneRow = 8.0
    private let disposeBag = DisposeBag()
    
    weak var sender: IMMsgSender?
    
    lazy var emojiView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumInteritemSpacing = 0
        let collectionView = UICollectionView(frame: self.frame, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.backgroundView = nil
        collectionView.backgroundColor = UIColor.clear
        collectionView.register(IMUnicodeEmojiCell.self, forCellWithReuseIdentifier: self.cellId)
        collectionView.alpha = 1
        return collectionView
    }()
    
    lazy var deleteButton: UIButton = {
        let button = UIButton.init(type: .roundedRect)
        button.setTitle("del", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.backgroundColor = .blue
        button.layer.cornerRadius = 6
        button.layer.masksToBounds = true
        return button
    }()
    
    lazy var sendButton: UIButton = {
        let button = UIButton.init(type: .roundedRect)
        button.setTitle("send", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.backgroundColor = .blue
        button.layer.cornerRadius = 6
        button.layer.masksToBounds = true
        return button
    }()
    
    // 来自: https://emojixd.com/
    lazy var emojis: Array<String> = {
       let emojis = [
            "😀", "😃", "😄", "😁", "😆", "😅", "🤣", "😂", "🙂", "🙃", "😉", "😊", "😇",
            "🥰", "😍", "🤩", "😘", "😗", "☺️", "😚", "😙", "🥲", "😋", "😛", "😜", "🤪",
            "😝", "🤑", "🤗", "🤭", "🤫", "🤔", "🤐", "🤨", "😐", "😑", "😶", "😏", "😒",
            "🙄", "😬", "🤥", "😶‍🌫️", "😮‍💨", "😌", "😔", "😪", "🤤", "😴", "😷", "🤒", "🤕",
            "🤢", "🤮", "🤧", "🥵", "🥶", "🥴", "😵", "🤯", "😵‍💫"
       ]
        return emojis
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override open func layoutSubviews() {
        updateUI()
    }
    
    func setupUI() {
        self.addSubview(self.emojiView)
        self.addSubview(self.sendButton)
        self.addSubview(self.deleteButton)
        
        self.sendButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.sender?.sendInputContent()
            }).disposed(by: disposeBag)
        
        self.deleteButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.sender?.deleteInputContent(count: 1)
            }).disposed(by: disposeBag)
    }
    
    func updateUI() {
        self.emojiView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalToSuperview().offset(-20)
        }
        
        self.sendButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-20)
            make.right.equalToSuperview().offset(-10)
            make.width.equalTo(40)
            make.height.equalTo(30)
        }
        
        self.deleteButton.snp.makeConstraints { [weak self] make in
            guard let sf = self else {
                return
            }
            make.bottom.equalToSuperview().offset(-20)
            make.right.equalTo(sf.sendButton.snp.left).offset(-10)
            make.width.equalTo(40)
            make.height.equalTo(30)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellId, for: indexPath)
        let emojiCell = cell as! IMUnicodeEmojiCell
        emojiCell.setEmoji(self.emojis[indexPath.row])
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.emojis.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let boundSize: CGFloat = UIScreen.main.bounds.width / countOneRow
        return CGSize(width: boundSize, height: boundSize)
    }
    
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.sender?.addInputContent(text: self.emojis[indexPath.row])
    }
    
    
}

