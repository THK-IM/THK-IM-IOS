//
//  IMMoreView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/9.
//

import Foundation
import UIKit
import RxSwift

class IMMoreView: UIView, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    weak var sender: IMMsgSender?
    private let cellID = "more_cell_id"
    private let countOneRow = 4.0
    private let disposeBag = DisposeBag()
    private let functions = IMUIManager.shared.getBottomFunctionProviders()
    
    lazy var moreView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .vertical
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.minimumInteritemSpacing = 0
        let collectionView = UICollectionView(frame: self.frame, collectionViewLayout: layout)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.isPagingEnabled = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundView = nil
        collectionView.backgroundColor = UIColor.clear
        collectionView.register(IMMoreCell.self, forCellWithReuseIdentifier: self.cellID)
        collectionView.alpha = 1
        return collectionView
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        self.addSubview(self.moreView)
        self.moreView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.cellID, for: indexPath)
        let moreCell = cell as! IMMoreCell
        moreCell.setFunction(functions[indexPath.row])
        return moreCell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return functions.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let boundSize: CGFloat = UIScreen.main.bounds.width / countOneRow
        print("boundSize: \(boundSize)")
        return CGSize(width: boundSize, height: boundSize)
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let f = functions[indexPath.row]
        guard let s = sender else {
            return
        }
        f.click(sender: s)
    }
    
    
}

