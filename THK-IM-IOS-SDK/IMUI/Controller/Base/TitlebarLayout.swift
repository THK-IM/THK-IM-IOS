//
//  TitlebarLayout.swift
//  THK-IM-IOS
//
//  Created by think on 2025/1/25.
//  Copyright © 2025 THK. All rights reserved.
//

import BadgeSwift
import UIKit

public typealias TitlebarItemAction = (_ action: String) -> Void

open class TitlebarLayout: UIView {

    private var tapAction: TitlebarItemAction? = nil

    public lazy var backView: UIImageView = {
        let v = UIImageView()
        v.isHidden = true
        v.isUserInteractionEnabled = true
        return v
    }()

    public lazy var titleLabel: UILabel = {
        let v = UILabel()
        v.numberOfLines = 1
        v.textAlignment = .center
        v.font = UIFont.boldSystemFont(ofSize: 16)
        v.textColor =
            IMUIManager.shared.uiResourceProvider?.inputTextColor()
            ?? UIColor.init(hex: "#333333")
        return v
    }()

    public lazy var addItem: UIImageView = {
        let v = UIImageView()
        v.isHidden = true
        v.contentMode = .center
        v.isUserInteractionEnabled = true
        return v
    }()

    public lazy var searchItem: UIImageView = {
        let v = UIImageView()
        v.isHidden = true
        v.contentMode = .center
        v.isUserInteractionEnabled = true
        return v
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = true
        self.addSubview(self.backView)
        self.addSubview(self.titleLabel)
        self.addSubview(self.addItem)
        self.addSubview(self.searchItem)

        let backTapGesture = UITapGestureRecognizer.init(
            target: self, action: #selector(self.backAction))
        backTapGesture.cancelsTouchesInView = false
        self.backView.addGestureRecognizer(backTapGesture)

        let addTapGesture = UITapGestureRecognizer.init(
            target: self, action: #selector(self.addTapped))
        addTapGesture.cancelsTouchesInView = false
        self.addItem.addGestureRecognizer(addTapGesture)

        let searchTapGesture = UITapGestureRecognizer.init(
            target: self, action: #selector(self.searchTapped))
        searchTapGesture.cancelsTouchesInView = false
        self.searchItem.addGestureRecognizer(searchTapGesture)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        self.layout()
    }

    open func layout() {
        self.backView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(8)
            make.centerY.equalToSuperview()
            make.size.equalTo(32)
        }
        
        if self.addItem.image != nil {
            self.addItem.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.right.equalToSuperview().offset(-8)
                make.size.equalTo(32)
            }
        } else {
            self.addItem.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.right.equalToSuperview()
                make.size.equalTo(0)
            }
        }
        if self.searchItem.image != nil {
            self.searchItem.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.right.equalTo(self.addItem.snp.left).offset(-8)
                make.size.equalTo(32)
            }
        } else {
            self.searchItem.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.right.equalTo(self.addItem.snp.left)
                make.size.equalTo(0)
            }
        }
        self.layoutTitle()
    }
    
    open func layoutTitle() {
        self.titleLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(64)
            make.right.equalToSuperview().offset(-80)
        }
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    open func setTapAction(action: TitlebarItemAction?) {
        self.tapAction = action
    }

    open func setTitle(_ title: String?, _ color: UIColor? = nil) {
        self.titleLabel.text = title
        if color != nil {
            self.titleLabel.textColor = color
        }
    }

    open func setBackItem(_ image: UIImage?) {
        self.backView.image = image
        self.backView.isHidden = image == nil
    }

    open func setAddRightItem(_ image: UIImage?) {
        self.addItem.image = image
        self.addItem.isHidden = image == nil
    }

    open func setSearchItem(_ image: UIImage?) {
        self.searchItem.image = image
        self.searchItem.isHidden = image == nil
    }

    @objc open func backAction() {
        self.tapAction?("back")
    }

    @objc open func addTapped() {
        self.tapAction?("add")
    }

    @objc open func searchTapped() {
        self.tapAction?("search")
    }

}
