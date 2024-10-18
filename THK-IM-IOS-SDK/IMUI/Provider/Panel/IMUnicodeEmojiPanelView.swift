//
//  UnicodeEmojiUIController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/10.
//

import Foundation
import UIKit

open class IMUnicodeEmojiPanelView: UIView, UICollectionViewDelegate, UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout
{

    private let cellId = "unicode_emoji_cell_id"
    private let countOneRow = 7.0

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

    // 来自: https://emojixd.com/
    lazy var emojis: [String] = {
        var emojis = IMUIManager.shared.uiResourceProvider?.unicodeEmojis()
        if emojis == nil {
            emojis = [
                "😀", "😃", "😄", "😁", "😆", "😅", "🤣", "😂", "🙂", "🙃", "😉", "😊", "😇",
                "🥰", "😍", "🤩", "😘", "😗", "☺️", "😚", "😙", "🥲", "😋", "😛", "😜", "🤪",
                "😝", "🤑", "🤗", "🤭", "🤫", "🤔", "🤐", "🤨", "😐", "😑", "😶", "😏", "😒",
                "🙄", "😬", "🤥", "😶‍🌫️", "😮‍💨", "😌", "😔", "😪", "🤤", "😴", "😷", "🤒", "🤕",
                "🤢", "🤮", "🤧", "🥵", "🥶", "🥴", "😵", "🤯", "😵‍💫",
            ]
        }
        return emojis!
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
    }

    func updateUI() {
        self.emojiView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

    }

    public func collectionView(
        _ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: self.cellId, for: indexPath)
        let emojiCell = cell as! IMUnicodeEmojiCell
        emojiCell.setEmoji(self.emojis[indexPath.row])
        return cell
    }

    public func collectionView(
        _ collectionView: UICollectionView, numberOfItemsInSection section: Int
    ) -> Int {
        return self.emojis.count
    }

    public func collectionView(
        _ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let boundSize: CGFloat = UIScreen.main.bounds.width / countOneRow
        return CGSize(width: boundSize, height: boundSize)
    }

    public func collectionView(
        _ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath
    ) {
        self.sender?.addInputContent(text: self.emojis[indexPath.row])
    }

}
