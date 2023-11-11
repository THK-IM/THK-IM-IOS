//
//  IMTabPanelView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/10.
//

import Foundation
import UIKit

class IMTabPanelView: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    
    private let cellId = "emoji_panel_cell"
    
    weak var sender: IMMsgSender?
    
    lazy var functionView: UICollectionView = {
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
        collectionView.register(IMTabCell.self, forCellWithReuseIdentifier: self.cellId)
        collectionView.alpha = 1
        return collectionView
    }()
    
    lazy var containerView: UIView = {
        let view = UIView()
        return view
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.functionView)
        self.functionView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalToSuperview()
            make.height.equalTo(40)
        }
        self.addSubview(self.containerView)
        self.containerView.snp.makeConstraints { [weak self] make in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
            guard let sf = self else {
                return
            }
            make.top.equalTo(sf.functionView.snp.bottom)
        }
        
    }
    
    func initPosition() {
        if (IMUIManager.shared.getPanelProviders().count > 0) {
            let view = IMUIManager.shared.getPanelProviders()[0].contentView(sender: self.sender)
            self.containerView.addSubview(view)
            view.snp.makeConstraints {make in
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellId, for: indexPath)
        let tabCell = cell as! IMTabCell
        let provider = IMUIManager.shared.getPanelProviders()[indexPath.row]
        tabCell.setProvider(provider)
        return cell
    }
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let boundSize: CGFloat = collectionView.frame.height
        return CGSize(width: boundSize, height: boundSize)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.containerView.subviews.forEach {
            $0.removeFromSuperview()
        }
        let provider = IMUIManager.shared.getPanelProviders()[indexPath.row]
        let view = provider.contentView(sender: self.sender)
        self.containerView.addSubview(view)
        view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
}
