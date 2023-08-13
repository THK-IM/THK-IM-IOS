//
//  UnicodeEmojiUIController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/10.
//

import Foundation
import UIKit
import RxSwift

open class IMUnicodeEmojiUIController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    private let cellID = "unicode_emoji_cell_id"
    private let countOneRow = 8.0
    private let disposeBag = DisposeBag()
    
    weak var sender: IMMsgSender?
    
    lazy var emojiView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumInteritemSpacing = 0
        let collectionView = UICollectionView(frame: self.view.frame, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundView = nil
        collectionView.backgroundColor = UIColor.clear
        collectionView.register(IMUnicodeEmojiCell.self, forCellWithReuseIdentifier: self.cellID)
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
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    private func setupView() {
        self.view.addSubview(self.emojiView)
        self.emojiView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        self.view.addSubview(self.sendButton)
        self.sendButton.snp.makeConstraints { make in
            make.bottom.equalToSuperview()
            make.right.equalToSuperview().offset(-10)
            make.width.equalTo(40)
            make.height.equalTo(30)
        }
        
        self.view.addSubview(self.deleteButton)
        self.deleteButton.snp.makeConstraints { [weak self] make in
            guard let sf = self else {
                return
            }
            make.bottom.equalToSuperview()
            make.right.equalTo(sf.sendButton.snp.left).offset(-8)
            make.width.equalTo(40)
            make.height.equalTo(30)
        }
        
        self.sendButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.sender?.sendInputContent()
            }).disposed(by: disposeBag)
        
        self.deleteButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.sender?.deleteInputContent(count: 1)
            }).disposed(by: disposeBag)
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellID, for: indexPath)
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

