//
//  IMMessageSelectedLayout.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/8.
//

import Foundation
import RxGesture
import RxSwift
import UIKit

public class IMMessageSelectedLayout: UIView {

    weak var sender: IMMsgSender?
    private let disposeBag = DisposeBag()
    private let iconSize = CGSize(width: 32.0, height: 32.0)
    var height = 60

    lazy private var contentView: UIStackView = {
        let v = UIStackView()
        v.axis = .horizontal
        v.distribution = .fillEqually
        v.alignment = .center
        v.addArrangedSubview(cancelButton)
        v.addArrangedSubview(deleteButton)
        v.addArrangedSubview(forwardButton)
        return v
    }()

    lazy private var deleteButton: UIImageView = {
        let button = UIImageView()
        let image = ResourceUtils.loadImage(named: "ic_msg_opr_delete")?.withTintColor(
            IMUIManager.shared.uiResourceProvider?.inputTextColor()
                ?? UIColor.init(hex: "333333")).scaledToSize(iconSize)
        if image != nil {
            button.image = image
            button.contentMode = .scaleAspectFit
            button.clipsToBounds = true
        }
        return button
    }()

    lazy private var forwardButton: UIImageView = {
        let button = UIImageView()
        let image = ResourceUtils.loadImage(named: "ic_msg_opr_forward")?.withTintColor(
            IMUIManager.shared.uiResourceProvider?.inputTextColor()
                ?? UIColor.init(hex: "333333")).scaledToSize(iconSize)
        if image != nil {
            button.image = image
            button.contentMode = .scaleAspectFit
            button.clipsToBounds = true
        }
        return button
    }()

    lazy private var cancelButton: UIImageView = {
        let button = UIImageView()
        let image = ResourceUtils.loadImage(named: "ic_msg_opr_cancel")?.withTintColor(
            IMUIManager.shared.uiResourceProvider?.inputTextColor()
                ?? UIColor.init(hex: "333333")).scaledToSize(iconSize)
        if image != nil {
            button.image = image
            button.contentMode = .scaleAspectFit
            button.clipsToBounds = true
        }
        return button
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        self.addSubview(self.contentView)
        self.contentView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.height.equalTo(height * 2 / 3)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        self.deleteButton.rx.tapGesture()
            .subscribe(onNext: { [weak self] event in
                guard let sf = self else {
                    return
                }
                sf.sender?.deleteSelectedMessages()
                sf.sender?.setSelectMode(false, message: nil)
            })
            .disposed(by: disposeBag)

        self.forwardButton.rx.tapGesture()
            .subscribe(onNext: { [weak self] event in
                guard let sf = self else {
                    return
                }
                sf.sender?.forwardSelectedMessages(forwardType: 1)
            })
            .disposed(by: disposeBag)
        self.cancelButton.rx.tapGesture()
            .subscribe(onNext: { [weak self] event in
                guard let sf = self else {
                    return
                }
                sf.sender?.setSelectMode(false, message: nil)
            })
            .disposed(by: disposeBag)
    }

    func getLayoutHeight() -> Int {
        return self.height
    }

    public override func layoutSubviews() {
        if let session = self.sender?.getSession() {
            self.forwardButton.isHidden =
                !(IMUIManager.shared.uiResourceProvider?.supportFunction(
                    session, IMChatFunction.Forward.rawValue) ?? false)
        }
    }
}
